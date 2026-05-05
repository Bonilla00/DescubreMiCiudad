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
app.use(express.json()); // ✅ Tarea 2: Asegurar express.json

const runMigrations = async () => {
    try {
        // ✅ Tarea 3: Crear tabla resenas si no existe (lugar_id como TEXT para flexibilidad)
        await pool.query(`
            CREATE TABLE IF NOT EXISTS resenas (
                id SERIAL PRIMARY KEY,
                lugar_id TEXT NOT NULL,
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

// ✅ Tarea 1 y 4: Endpoint /reviews con Logs
app.post('/reviews', async (req, res) => {
    console.log("📥 BODY RECIBIDO:", req.body); // Logs para debug
    try {
        const { lugar_id, comentario, rating } = req.body;

        if (!lugar_id || !comentario || !rating) {
            console.log("⚠️ Datos incompletos");
            return res.status(400).json({ error: 'Datos incompletos' });
        }

        await pool.query(
            'INSERT INTO resenas (lugar_id, comentario, rating) VALUES ($1, $2, $3)',
            [lugar_id.toString(), comentario, rating]
        );

        console.log("✅ Reseña guardada");
        res.status(201).json({ message: 'Reseña guardada' });
    } catch (error) {
        console.error('❌ ERROR SQL:', error);
        res.status(500).json({ error: 'Error al guardar reseña' });
    }
});

// --- OTROS ENDPOINTS ---

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

// ✅ Tarea 5: Puerto para Railway
app.listen(PORT, () => {
    console.log(`🚀 Servidor en puerto ${PORT}`);
});
