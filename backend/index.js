const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
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
        // Asegurar tabla reseñas
        await pool.query(`
            CREATE TABLE IF NOT EXISTS resenas (
                id SERIAL PRIMARY KEY,
                lugar_id TEXT NOT NULL,
                usuario TEXT NOT NULL,
                comentario TEXT,
                rating INTEGER NOT NULL,
                fecha TIMESTAMP DEFAULT NOW()
            )
        `);
        console.log('✅ Base de datos lista (Tablas verificadas).');
    } catch (err) {
        console.error('❌ Error en migración:', err);
    }
};
runMigrations();

// --- ENDPOINTS RESEÑAS ---

// Obtener todas las reseñas de un lugar (Ordenadas por rating desc)
app.get('/resenas/:lugarId', async (req, res) => {
    try {
        const { lugarId } = req.params;
        const { rows } = await pool.query(
            'SELECT * FROM resenas WHERE lugar_id = $1 ORDER BY rating DESC, fecha DESC',
            [lugarId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: 'Error obteniendo reseñas' });
    }
});

// Obtener promedio y total de reseñas
app.get('/resenas/promedio/:lugarId', async (req, res) => {
    try {
        const { lugarId } = req.params;
        const { rows } = await pool.query(
            'SELECT COALESCE(AVG(rating), 0) as promedio, COUNT(*) as total FROM resenas WHERE lugar_id = $1',
            [lugarId]
        );
        res.json({
            promedio: parseFloat(rows[0].promedio).toFixed(1),
            total: parseInt(rows[0].total)
        });
    } catch (err) {
        res.status(500).json({ error: 'Error calculando promedio' });
    }
});

// Publicar reseña
app.post('/api/resenas', async (req, res) => {
    const { lugar_id, usuario, comentario, rating } = req.body;
    try {
        const { rows } = await pool.query(
            'INSERT INTO resenas (lugar_id, usuario, comentario, rating) VALUES ($1, $2, $3, $4) RETURNING *',
            [lugar_id, usuario, comentario, rating]
        );
        res.status(201).json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: 'Error al publicar reseña' });
    }
});

// --- LUGARES (GOOGLE PLACES) ---
app.get('/lugares', async (req, res) => {
    const { lat, lng } = req.query;
    if (!GOOGLE_API_KEY) return res.status(500).json({ error: "API Key missing" });

    try {
        const location = lat && lng ? `${lat},${lng}` : "3.4516,-76.5320";
        const response = await axios.get(
            `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location}&radius=2000&type=restaurant&key=${GOOGLE_API_KEY}`
        );

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
