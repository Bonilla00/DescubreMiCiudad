const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const { calcularDistancia, calcularTiempos } = require('./src/utils/distancia');
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

// --- ENDPOINT SOLICITADO: /lugares ---
// Explicación: Se coloca fuera de /api para cumplir con el requerimiento directo.
// El error "Cannot GET /lugares" ocurría porque probablemente estaba bajo /api/lugares o no existía.
app.get('/lugares', async (req, res) => {
    console.log("🚀 Endpoint /lugares llamado");
    const { lat, lng } = req.query;

    // Si no hay API KEY, devolvemos un error claro
    if (!GOOGLE_API_KEY) {
        console.error("❌ ERROR: GOOGLE_API_KEY no configurada en variables de entorno.");
        return res.status(500).json({ error: "Google API Key no configurada en el servidor" });
    }

    try {
        const location = lat && lng ? `${lat},${lng}` : "3.4516,-76.5320"; // Cali por defecto
        console.log(`🔍 Buscando en Google Places cerca de: ${location}`);

        const response = await axios.get(
            `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${location}&radius=2000&type=restaurant&key=${GOOGLE_API_KEY}`
        );

        if (response.data.status !== "OK" && response.data.status !== "ZERO_RESULTS") {
            throw new Error(`Google API Error: ${response.data.status}`);
        }

        const restaurantes = response.data.results.map((place) => {
            const photoReference = place.photos?.[0]?.photo_reference;
            const imagenUrl = photoReference
                ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${photoReference}&key=${GOOGLE_API_KEY}`
                : "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4"; // Fallback

            return {
                id: place.place_id,
                nombre: place.name,
                descripcion: place.vicinity || "Restaurante en Cali",
                imagen: imagenUrl,
                rating: place.rating || 0.0,
                precio: "$".repeat(place.price_level || 2),
                latitud: place.geometry.location.lat,
                longitud: place.geometry.location.lng,
                direccion: place.vicinity,
                como_llegar: `https://www.google.com/maps/dir/?api=1&destination=${place.geometry.location.lat},${place.geometry.location.lng}`
            };
        });

        res.json(restaurantes);
    } catch (error) {
        console.error("❌ Error en /lugares:", error.message);
        res.status(500).json({ error: error.message });
    }
});

// --- MANTENER OTROS ENDPOINTS (Opcional pero recomendado para no romper la app) ---

app.post('/api/auth/register', async (req, res) => {
    let { nombre, email, password } = req.body;
    if (!nombre || !email || !password) return res.status(400).json({ error: "Campos requeridos" });
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        const result = await pool.query(
            'INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3) RETURNING id, nombre, email',
            [nombre, email, hashedPassword]
        );
        res.status(201).json({ usuario: result.rows[0] });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/auth/login', async (req, res) => {
    let { email, password } = req.body;
    try {
        const { rows } = await pool.query('SELECT * FROM usuarios WHERE email = $1', [email]);
        if (rows.length === 0) return res.status(401).json({ error: "Usuario no encontrado" });
        const valid = await bcrypt.compare(password, rows[0].password);
        if (!valid) return res.status(401).json({ error: "Password incorrecto" });
        const token = jwt.sign({ userId: rows[0].id }, JWT_SECRET, { expiresIn: '7d' });
        res.json({ token, usuario: rows[0] });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en puerto ${PORT}`);
});
