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
        // Tabla Usuarios
        await pool.query(`
            CREATE TABLE IF NOT EXISTS usuarios (
                id SERIAL PRIMARY KEY,
                nombre TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                avatar TEXT DEFAULT 'https://i.pravatar.cc/150'
            )
        `);
        // Tabla Reseñas (lugar_id como TEXT para soportar Google Place ID)
        await pool.query(`
            CREATE TABLE IF NOT EXISTS resenas (
                id SERIAL PRIMARY KEY,
                lugar_id TEXT NOT NULL,
                usuario_id INTEGER REFERENCES usuarios(id),
                comentario TEXT,
                rating INTEGER NOT NULL,
                fecha TIMESTAMP DEFAULT NOW()
            )
        `);
        // Tabla Likes
        await pool.query(`
            CREATE TABLE IF NOT EXISTS likes (
                id SERIAL PRIMARY KEY,
                resena_id INTEGER REFERENCES resenas(id) ON DELETE CASCADE,
                usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
                UNIQUE(resena_id, usuario_id)
            )
        `);
        // Tabla Favoritos
        await pool.query(`
            CREATE TABLE IF NOT EXISTS favoritos (
                id SERIAL PRIMARY KEY,
                usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
                lugar_id TEXT NOT NULL,
                UNIQUE(usuario_id, lugar_id)
            )
        `);
        console.log('✅ Migraciones completadas.');
    } catch (err) {
        console.error('❌ Error en migración:', err);
    }
};
runMigrations();

// Middleware de Autenticación
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];
    if (!token) return res.status(401).json({ error: "Token requerido" });
    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ error: "Token inválido" });
        req.user = user;
        next();
    });
};

// --- AUTH ---
app.post('/api/auth/register', async (req, res) => {
    const { nombre, email, password } = req.body;
    try {
        const hashed = await bcrypt.hash(password, 10);
        const { rows } = await pool.query(
            'INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3) RETURNING id, nombre, email, avatar',
            [nombre, email, hashed]
        );
        res.status(201).json(rows[0]);
    } catch (err) { res.status(500).json({ error: "Email ya registrado o error de servidor" }); }
});

app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        const { rows } = await pool.query('SELECT * FROM usuarios WHERE email = $1', [email]);
        if (rows.length === 0) return res.status(401).json({ error: "Usuario no encontrado" });
        const valid = await bcrypt.compare(password, rows[0].password);
        if (!valid) return res.status(401).json({ error: "Contraseña incorrecta" });
        const token = jwt.sign({ userId: rows[0].id, nombre: rows[0].nombre }, JWT_SECRET, { expiresIn: '30d' });
        res.json({ token, user: { id: rows[0].id, nombre: rows[0].nombre, avatar: rows[0].avatar } });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- LIKES ---
app.post('/likes/:resenaId', authenticateToken, async (req, res) => {
    try {
        await pool.query(
            'INSERT INTO likes (resena_id, usuario_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [req.params.resenaId, req.user.userId]
        );
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/likes/:resenaId', authenticateToken, async (req, res) => {
    try {
        await pool.query('DELETE FROM likes WHERE resena_id = $1 AND usuario_id = $2', [req.params.resenaId, req.user.userId]);
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- FAVORITOS ---
app.post('/favoritos/:lugarId', authenticateToken, async (req, res) => {
    try {
        await pool.query(
            'INSERT INTO favoritos (usuario_id, lugar_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [req.user.userId, req.params.lugarId]
        );
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.delete('/favoritos/:lugarId', authenticateToken, async (req, res) => {
    try {
        await pool.query('DELETE FROM favoritos WHERE usuario_id = $1 AND lugar_id = $2', [req.user.userId, req.params.lugarId]);
        res.json({ success: true });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/favoritos', authenticateToken, async (req, res) => {
    try {
        const { rows } = await pool.query('SELECT lugar_id FROM favoritos WHERE usuario_id = $1', [req.user.userId]);
        res.json(rows.map(r => r.lugar_id));
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- RESEÑAS (Actualizado con Likes) ---
app.get('/resenas/:lugarId', async (req, res) => {
    try {
        const { rows } = await pool.query(`
            SELECT r.*, u.nombre as usuario, u.avatar,
            (SELECT COUNT(*) FROM likes WHERE resena_id = r.id) as likes
            FROM resenas r
            JOIN usuarios u ON r.usuario_id = u.id
            WHERE r.lugar_id = $1
            ORDER BY likes DESC, r.fecha DESC`,
            [req.params.lugarId]
        );
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/resenas', authenticateToken, async (req, res) => {
    const { lugar_id, comentario, rating } = req.body;
    try {
        const { rows } = await pool.query(
            'INSERT INTO resenas (lugar_id, usuario_id, comentario, rating) VALUES ($1, $2, $3, $4) RETURNING *',
            [lugar_id, req.user.userId, comentario, rating]
        );
        res.status(201).json(rows[0]);
    } catch (err) { res.status(500).json({ error: err.message }); }
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
