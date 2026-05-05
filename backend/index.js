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
app.use(express.json()); // 🔥 ASEGURAR: Parsing de JSON

const runMigrations = async () => {
    try {
        // Asegurar tabla usuarios
        await pool.query(`
            CREATE TABLE IF NOT EXISTS usuarios (
                id SERIAL PRIMARY KEY,
                nombre TEXT NOT NULL,
                email TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                avatar TEXT DEFAULT 'https://i.pravatar.cc/150'
            )
        `);
        // Asegurar tabla reseñas
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
        console.log('✅ Base de datos lista.');
    } catch (err) {
        console.error('❌ Error en migración:', err);
    }
};
runMigrations();

// 🔥 ARREGLAR ENDPOINT: Registro con errores reales
app.post('/auth/register', async (req, res) => {
    try {
        console.log("📥 BODY RECIBIDO:", req.body);
        const { nombre, email, password } = req.body;

        // 1. Validación de campos
        if (!nombre || !email || !password) {
            return res.status(400).json({ error: 'Datos incompletos: nombre, email y password son requeridos' });
        }

        // 2. Verificar si el correo ya existe
        const existing = await pool.query(
            'SELECT * FROM usuarios WHERE email = $1',
            [email.toLowerCase().trim()]
        );

        if (existing.rows.length > 0) {
            return res.status(400).json({ error: 'El correo ya está registrado' });
        }

        // 3. Encriptar contraseña (Opcional pero recomendado para Senior)
        // Por ahora lo guardamos directo según tu requerimiento exacto
        await pool.query(
            'INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3)',
            [nombre.trim(), email.toLowerCase().trim(), password]
        );

        console.log("✅ Usuario creado correctamente:", email);
        res.status(201).json({ message: 'Usuario creado correctamente' });

    } catch (error) {
        console.error("❌ ERROR REGISTER:", error);
        res.status(500).json({
            error: 'Error interno en el servidor',
            detalle: error.message
        });
    }
});

app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        const { rows } = await pool.query('SELECT * FROM usuarios WHERE email = $1', [email.toLowerCase().trim()]);
        if (rows.length === 0) return res.status(401).json({ error: "Usuario no encontrado" });

        // Verificación simple (ajustar si usas bcrypt)
        if (rows[0].password !== password) return res.status(401).json({ error: "Contraseña incorrecta" });

        const token = jwt.sign({ userId: rows[0].id, nombre: rows[0].nombre }, JWT_SECRET, { expiresIn: '30d' });
        res.json({ token, user: { id: rows[0].id, nombre: rows[0].nombre, avatar: rows[0].avatar } });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- LIKES Y RESEÑAS (Simplificados para esta entrega) ---
app.post('/reviews', async (req, res) => {
    try {
        const { lugar_id, comentario, rating } = req.body;
        await pool.query('INSERT INTO resenas (lugar_id, comentario, rating) VALUES ($1, $2, $3)', [lugar_id, comentario, rating]);
        res.status(201).json({ message: 'Reseña guardada' });
    } catch (error) { res.status(500).json({ error: error.message }); }
});

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
