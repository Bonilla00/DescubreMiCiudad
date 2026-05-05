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
    ssl: { rejectUnauthorized: false }
});

pool.connect()
    .then(() => console.log("✅ Conectado a PostgreSQL"))
    .catch(err => console.error("❌ Error conexión DB:", err.message));

// 🔥 RECONSTRUCCIÓN TOTAL (RESET)
(async () => {
    try {
        console.log("🧹 Iniciando reconstrucción total...");

        // BORRADO DE TABLAS ANTIGUAS
        await pool.query('DROP TABLE IF EXISTS favoritos, resenas CASCADE;');

        // CREACIÓN DE TABLAS LIMPIAS
        await pool.query(`
            CREATE TABLE IF NOT EXISTS usuarios (
                id SERIAL PRIMARY KEY,
                nombre TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                avatar TEXT DEFAULT 'https://i.pravatar.cc/150'
            );

            CREATE TABLE favoritos (
                id SERIAL PRIMARY KEY,
                usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
                lugar_id TEXT NOT NULL,
                creado_en TIMESTAMP DEFAULT NOW(),
                UNIQUE(usuario_id, lugar_id)
            );

            CREATE TABLE resenas (
                id SERIAL PRIMARY KEY,
                usuario_id INTEGER NOT NULL REFERENCES usuarios(id) ON DELETE CASCADE,
                lugar_id TEXT NOT NULL,
                comentario TEXT NOT NULL,
                rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
                creado_en TIMESTAMP DEFAULT NOW()
            );
        `);
        console.log("✅ Tablas reconstruidas desde cero.");
    } catch (err) {
        console.error("❌ Error en reconstrucción:", err.message);
    }
})();

app.use(cors());
app.use(express.json());

// --- AUTH ---
app.post('/api/auth/register', async (req, res) => {
    try {
        const { nombre, email, password } = req.body;
        const hashedPassword = await bcrypt.hash(password, 10);
        await pool.query('INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3)', [nombre, email.toLowerCase().trim(), hashedPassword]);
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

// --- PERFIL ---
app.put('/api/user/update/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const { nombre, email, avatar } = req.body;
        await pool.query('UPDATE usuarios SET nombre = $1, email = $2, avatar = $3 WHERE id = $4', [nombre, email, avatar, id]);
        res.json({ ok: true });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

// --- FAVORITOS ---
app.post('/api/favoritos', async (req, res) => {
    try {
        const { usuario_id, lugar_id } = req.body;
        await pool.query('INSERT INTO favoritos (usuario_id, lugar_id) VALUES ($1, $2) ON CONFLICT DO NOTHING', [usuario_id, lugar_id]);
        res.json({ ok: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/api/favoritos/:userId/:lugarId', async (req, res) => {
    try {
        const { userId, lugarId } = req.params;
        await pool.query('DELETE FROM favoritos WHERE usuario_id = $1 AND lugar_id = $2', [userId, lugarId]);
        res.json({ ok: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/favoritos/:userId/:lugarId', async (req, res) => {
    try {
        const { userId, lugarId } = req.params;
        const result = await pool.query('SELECT 1 FROM favoritos WHERE usuario_id=$1 AND lugar_id=$2', [userId, lugarId]);
        res.json({ isFavorite: result.rows.length > 0 });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- RESEÑAS ---
app.post('/api/resenas', async (req, res) => {
    try {
        const { usuario_id, lugar_id, comentario, rating } = req.body;
        await pool.query('INSERT INTO resenas (usuario_id, lugar_id, comentario, rating) VALUES ($1, $2, $3, $4)', [usuario_id, lugar_id, comentario, rating]);
        res.json({ ok: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/resenas/:lugarId', async (req, res) => {
    try {
        const { lugarId } = req.params;
        const result = await pool.query(`
            SELECT r.*, u.nombre as usuario, u.avatar
            FROM resenas r
            JOIN usuarios u ON r.usuario_id = u.id
            WHERE r.lugar_id=$1
            ORDER BY r.creado_en DESC`, [lugarId]);
        res.json(result.rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- GOOGLE PLACES PROXY ---
app.get('/lugares', async (req, res) => {
    const { lat, lng } = req.query;
    try {
        const location = lat && lng ? `${lat},${lng}` : "3.4516,-76.5320";
        const response = await axios.get(`https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location}&radius=2000&type=restaurant&key=${GOOGLE_API_KEY}`);
        res.json(response.data.results.map(p => ({
            id: p.place_id, nombre: p.name, latitud: p.geometry.location.lat, longitud: p.geometry.location.lng,
            imagen: p.photos ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${p.photos[0].photo_reference}&key=${GOOGLE_API_KEY}` : "",
            rating: p.rating, descripcion: p.vicinity
        })));
    } catch (error) { res.status(500).json({ error: error.message }); }
});

app.get('/api/user/stats/:userId', async (req, res) => {
    try {
        const { userId } = req.params;
        const resenas = await pool.query('SELECT COUNT(*) FROM resenas WHERE usuario_id = $1', [userId]);
        const favoritos = await pool.query('SELECT COUNT(*) FROM favoritos WHERE usuario_id = $1', [userId]);
        res.json({ resenas: parseInt(resenas.rows[0].count), favoritos: parseInt(favoritos.rows[0].count) });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

app.listen(PORT, () => console.log(`🚀 Servidor reconstruido en puerto ${PORT}`));
