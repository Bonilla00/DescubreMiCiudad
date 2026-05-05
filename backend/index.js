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
        console.log('✅ Base de datos lista.');
    } catch (err) {
        console.error('❌ Error en migración:', err);
    }
};
runMigrations();

// 🔥 ENDPOINT DE LOGIN CORREGIDO
app.post('/api/auth/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        console.log("🔑 Intento de login para:", email);

        if (!email || !password) {
            return res.status(400).json({ error: "Email y password requeridos" });
        }

        const cleanEmail = email.toLowerCase().trim();
        const { rows } = await pool.query('SELECT * FROM usuarios WHERE email = $1', [cleanEmail]);

        if (rows.length === 0) {
            console.log("❌ Usuario no encontrado");
            return res.status(401).json({ error: "Credenciales inválidas" });
        }

        const user = rows[0];
        if (user.password !== password) {
            console.log("❌ Password incorrecto");
            return res.status(401).json({ error: "Credenciales inválidas" });
        }

        const token = jwt.sign({ userId: user.id, nombre: user.nombre }, JWT_SECRET, { expiresIn: '30d' });

        console.log("✅ Login exitoso");
        res.json({
            token,
            user: { id: user.id, nombre: user.nombre, avatar: user.avatar }
        });

    } catch (err) {
        console.error("❌ ERROR LOGIN:", err);
        res.status(500).json({ error: "Error interno" });
    }
});

// 🔥 ENDPOINT DE REGISTRO CON LOGS COMPLETOS
app.post('/auth/register', async (req, res) => {
    try {
        console.log("📥 BODY RECIBIDO:", req.body);
        const { nombre, email, password } = req.body;

        if (!nombre || !email || !password) {
            console.log("⚠️ Datos incompletos");
            return res.status(400).json({ error: 'Datos incompletos' });
        }

        const cleanEmail = email.toLowerCase().trim();
        const existing = await pool.query(
            'SELECT * FROM usuarios WHERE email = $1',
            [cleanEmail]
        );

        if (existing.rows.length > 0) {
            console.log("⚠️ El correo ya existe:", cleanEmail);
            return res.status(400).json({ error: 'El correo ya está registrado' });
        }

        await pool.query(
            'INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3)',
            [nombre.trim(), cleanEmail, password]
        );

        console.log("✅ Usuario creado correctamente:", cleanEmail);
        res.status(201).json({ message: 'Usuario creado correctamente' });

    } catch (error) {
        console.error("❌ ERROR REGISTER:", error);
        res.status(500).json({
            error: 'Error interno',
            detalle: error.message
        });
    }
});

// --- OTROS ENDPOINTS ---
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
