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
            )
        `);
        await pool.query(`
            CREATE TABLE IF NOT EXISTS resenas (
                id SERIAL PRIMARY KEY,
                usuario_id INTEGER REFERENCES usuarios(id),
                lugar_id TEXT NOT NULL,
                comentario TEXT,
                rating INTEGER NOT NULL,
                fecha TIMESTAMP DEFAULT NOW()
            )
        `);
        await pool.query(`
            CREATE TABLE IF NOT EXISTS favoritos (
                id SERIAL PRIMARY KEY,
                usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
                lugar_id TEXT NOT NULL,
                UNIQUE(usuario_id, lugar_id)
            )
        `);
        console.log('✅ Base de datos lista.');
    } catch (err) {
        console.error('❌ Error en migración:', err);
    }
};
runMigrations();

// 🔥 ENDPOINT DINÁMICO: Estadísticas del usuario
app.get('/api/user/stats/:userId', async (req, res) => {
    try {
        const { userId } = req.params;

        const resenas = await pool.query(
            'SELECT COUNT(*) FROM resenas WHERE usuario_id = $1',
            [userId]
        );

        const favoritos = await pool.query(
            'SELECT COUNT(*) FROM favoritos WHERE usuario_id = $1',
            [userId]
        );

        res.json({
            resenas: parseInt(resenas.rows[0].count),
            favoritos: parseInt(favoritos.rows[0].count),
        });
    } catch (error) {
        console.error("❌ Error stats:", error);
        res.status(500).json({ error: 'Error obteniendo stats' });
    }
});

// --- AUTH ---
app.post('/api/auth/register', async (req, res) => {
    try {
        const { nombre, email, password } = req.body;
        if (!nombre || !email || !password) return res.status(400).json({ error: 'Datos incompletos' });
        const cleanEmail = email.toLowerCase().trim();
        const existing = await pool.query('SELECT * FROM usuarios WHERE email = $1', [cleanEmail]);
        if (existing.rows.length > 0) return res.status(400).json({ error: 'El correo ya está registrado' });

        const hashedPassword = await bcrypt.hash(password, 10);
        await pool.query(
            'INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3)',
            [nombre.trim(), cleanEmail, hashedPassword]
        );
        res.status(201).json({ message: 'Usuario creado correctamente' });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        const cleanEmail = email.toLowerCase().trim();
        const { rows } = await pool.query('SELECT * FROM usuarios WHERE email = $1', [cleanEmail]);
        if (rows.length === 0) return res.status(401).json({ error: "Credenciales inválidas" });

        const user = rows[0];
        const validPassword = await bcrypt.compare(password, user.password);
        if (!validPassword) return res.status(401).json({ error: "Credenciales inválidas" });

        const token = jwt.sign({ userId: user.id, nombre: user.nombre }, JWT_SECRET, { expiresIn: '30d' });
        res.json({
            token,
            user: { id: user.id, nombre: user.nombre, avatar: user.avatar }
        });
    } catch (err) { res.status(500).json({ error: "Error interno" }); }
});

// --- LUGARES ---
app.get('/lugares', async (req, res) => {
    const { lat, lng } = req.query;
    if (!GOOGLE_API_KEY) return res.status(500).json({ error: "API Key missing" });
    try {
        const location = lat && lng ? `${lat},${lng}` : "3.4516,-76.5320";
        const response = await axios.get(`https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location}&radius=2000&type=restaurant&key=${GOOGLE_API_KEY}`);
        const restaurantes = response.data.results.map((place) => ({
            id: place.place_id,
            nombre: place.name,
            descripcion: place.vicinity,
            imagen: place.photos ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${place.photos[0].photo_reference}&key=${GOOGLE_API_KEY}` : "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4",
            rating: place.rating || 0.0,
            precio: "$".repeat(place.price_level || 2),
            latitud: place.geometry.location.lat,
            longitud: place.geometry.location.lng,
        }));
        res.json(restaurantes);
    } catch (error) { res.status(500).json({ error: error.message }); }
});

app.listen(PORT, () => console.log(`🚀 Servidor en puerto ${PORT}`));
