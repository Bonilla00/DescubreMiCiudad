const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'mi_secreto_super_seguro';
const GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;

const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: process.env.NODE_ENV === 'production'
        ? { rejectUnauthorized: false }
        : false
});

app.use(cors());
app.use(express.json());

const runMigrations = async () => {
    try {
        await pool.query(`
            CREATE TABLE IF NOT EXISTS usuarios (
                id SERIAL PRIMARY KEY,
                nombre TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                avatar TEXT DEFAULT 'https://i.pravatar.cc/150'
            );

            CREATE TABLE IF NOT EXISTS resenas (
                id SERIAL PRIMARY KEY,
                lugar_id TEXT NOT NULL,
                usuario_id INTEGER REFERENCES usuarios(id),
                usuario_nombre TEXT,
                comentario TEXT NOT NULL,
                rating INTEGER NOT NULL,
                fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );

            CREATE TABLE IF NOT EXISTS favoritos (
                id SERIAL PRIMARY KEY,
                usuario_id INTEGER REFERENCES usuarios(id),
                lugar_id TEXT NOT NULL,
                fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                UNIQUE(usuario_id, lugar_id)
            );
        `);
        console.log('✅ Base de datos lista.');
    } catch (err) {
        console.error('❌ Error en migración:', err);
    }
};
runMigrations();

// 🔥 ENDPOINT ACTUALIZAR PERFIL
app.put('/api/user/update/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, email, avatar } = req.body;

        if (!nombre || !email) {
            return res.status(400).json({ error: 'Datos incompletos' });
        }

        await pool.query(
            'UPDATE usuarios SET nombre = $1, email = $2, avatar = $3 WHERE id = $4',
            [nombre.trim(), email.toLowerCase().trim(), avatar, id]
        );

        res.json({ message: 'Perfil actualizado' });
    } catch (error) {
        console.error("❌ Error update:", error);
        res.status(500).json({ error: 'Error actualizando perfil' });
    }
});

// --- ENDPOINTS RESEÑAS ---

app.get('/api/resenas/:lugarId', async (req, res) => {
    try {
        const { lugarId } = req.params;
        const { rows } = await pool.query(
            'SELECT r.*, u.nombre as usuario_nombre_real FROM resenas r LEFT JOIN usuarios u ON r.usuario_id = u.id WHERE r.lugar_id = $1 ORDER BY r.fecha DESC',
            [lugarId]
        );
        // Formatear para el frontend
        const resenas = rows.map(r => ({
            id: r.id,
            lugar_id: r.lugar_id,
            usuario: r.usuario_nombre_real || r.usuario_nombre || "Anónimo",
            comentario: r.comentario,
            rating: r.rating,
            fecha: r.fecha
        }));
        res.json(resenas);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

app.post('/api/resenas', async (req, res) => {
    try {
        const { lugar_id, usuario_id, usuario_nombre, comentario, rating } = req.body;

        if (!lugar_id || !comentario || !rating) {
            return res.status(400).json({ error: "Datos incompletos" });
        }

        await pool.query(
            'INSERT INTO resenas (lugar_id, usuario_id, usuario_nombre, comentario, rating) VALUES ($1, $2, $3, $4, $5)',
            [lugar_id, usuario_id, usuario_nombre, comentario, rating]
        );

        res.status(201).json({ message: "Reseña guardada" });
    } catch (error) {
        console.error("❌ Error reseña:", error);
        res.status(500).json({ error: "Error al guardar reseña" });
    }
});

// --- ENDPOINTS FAVORITOS ---

app.post('/api/favoritos', async (req, res) => {
    try {
        const { usuario_id, lugar_id } = req.body;
        if (!usuario_id || !lugar_id) return res.status(400).json({ error: "Datos incompletos" });

        await pool.query(
            'INSERT INTO favoritos (usuario_id, lugar_id) VALUES ($1, $2) ON CONFLICT (usuario_id, lugar_id) DO NOTHING',
            [usuario_id, lugar_id]
        );
        res.status(201).json({ message: 'Agregado a favoritos' });
    } catch (error) {
        console.error("❌ Error add favorito:", error);
        res.status(500).json({ error: 'Error al agregar a favoritos' });
    }
});

app.delete('/api/favoritos/:userId/:lugarId', async (req, res) => {
    try {
        const { userId, lugarId } = req.params;
        if (!userId || !lugarId) return res.status(400).json({ error: "Datos incompletos" });

        await pool.query(
            'DELETE FROM favoritos WHERE usuario_id = $1 AND lugar_id = $2',
            [userId, lugarId]
        );
        res.json({ message: 'Eliminado de favoritos' });
    } catch (error) {
        console.error("❌ Error delete favorito:", error);
        res.status(500).json({ error: 'Error al eliminar favorito' });
    }
});

app.get('/api/favoritos/:userId/:lugarId', async (req, res) => {
    try {
        const { userId, lugarId } = req.params;
        const result = await pool.query(
            'SELECT * FROM favoritos WHERE usuario_id = $1 AND lugar_id = $2',
            [userId, lugarId]
        );
        res.json({ isFavorite: result.rows.length > 0 });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
});

// --- OTROS ENDPOINTS (STATS, AUTH, LUGARES) ---

app.get('/api/user/stats/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const resenas = await pool.query('SELECT COUNT(*) FROM resenas WHERE usuario_id = $1', [userId]);
        const favoritos = await pool.query('SELECT COUNT(*) FROM favoritos WHERE usuario_id = $1', [userId]);
        res.json({
            resenas: parseInt(resenas.rows[0].count),
            favoritos: parseInt(favoritos.rows[0].count),
        });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

app.post('/api/auth/register', async (req, res) => {
    try {
        const { nombre, email, password } = req.body;
        const cleanEmail = email.toLowerCase().trim();
        const hashedPassword = await bcrypt.hash(password, 10);
        await pool.query('INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3)', [nombre.trim(), cleanEmail, hashedPassword]);
        res.status(201).json({ message: 'Usuario creado' });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const { rows } = await pool.query('SELECT * FROM usuarios WHERE email = $1', [email.toLowerCase().trim()]);
        if (rows.length === 0) return res.status(401).json({ error: "Credenciales inválidas" });
        const user = rows[0];
        const valid = await bcrypt.compare(password, user.password);
        if (!valid) return res.status(401).json({ error: "Credenciales inválidas" });
        const token = jwt.sign({ userId: user.id, nombre: user.nombre }, JWT_SECRET, { expiresIn: '30d' });
        res.json({ token, user: { id: user.id, nombre: user.nombre, avatar: user.avatar } });
    } catch (err) { res.status(500).json({ error: "Error interno" }); }
});

app.get('/lugares', async (req, res) => {
    const { lat, lng } = req.query;
    try {
        const location = lat && lng ? `${lat},${lng}` : "3.4516,-76.5320";
        const response = await axios.get(`https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location}&radius=2000&type=restaurant&key=${GOOGLE_API_KEY}`);
        res.json(response.data.results.map(p => ({
            id: p.place_id, nombre: p.name, latitud: p.geometry.location.lat, longitud: p.geometry.location.lng, imagen: p.photos ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${p.photos[0].photo_reference}&key=${GOOGLE_API_KEY}` : ""
        })));
    } catch (error) { res.status(500).json({ error: error.message }); }
});

app.listen(PORT, () => console.log(`🚀 Servidor en puerto ${PORT}`));
