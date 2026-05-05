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
app.use(express.json()); // 3. ASEGURAR: Parsing de JSON

const runMigrations = async () => {
    try {
        // 2. CREAR TABLA SI NO EXISTE: reseñas
        await pool.query(`
            CREATE TABLE IF NOT EXISTS resenas (
                id SERIAL PRIMARY KEY,
                lugar_id TEXT NOT NULL, -- Cambiado a TEXT para soportar Google Place ID
                usuario TEXT DEFAULT 'Usuario',
                comentario TEXT,
                rating INTEGER NOT NULL,
                fecha TIMESTAMP DEFAULT NOW()
            )
        `);
        console.log('✅ Base de datos lista (Migración de reseñas exitosa).');
    } catch (err) {
        console.error('❌ Error en migración:', err);
    }
};
runMigrations();

// --- 1. CREAR ENDPOINT: POST /reviews ---
app.post('/reviews', async (req, res) => {
    console.log("📥 Recibiendo reseña:", req.body);
    try {
        const { lugar_id, comentario, rating } = req.body;

        if (!lugar_id || !comentario || !rating) {
            return res.status(400).json({ error: 'Datos incompletos: lugar_id, comentario y rating son requeridos' });
        }

        await pool.query(
            'INSERT INTO resenas (lugar_id, comentario, rating) VALUES ($1, $2, $3)',
            [lugar_id, comentario, rating]
        );

        res.status(201).json({ message: 'Reseña guardada correctamente' });
    } catch (error) {
        console.error("❌ Error al guardar reseña:", error.message);
        res.status(500).json({ error: 'Error al guardar reseña en la base de datos' });
    }
});

// --- OTROS ENDPOINTS (MANTENIDOS) ---

app.get('/resenas/:lugarId', async (req, res) => {
    try {
        const { lugarId } = req.params;
        const { rows } = await pool.query(
            'SELECT * FROM resenas WHERE lugar_id = $1 ORDER BY fecha DESC',
            [lugarId]
        );
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
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
