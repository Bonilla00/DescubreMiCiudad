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
        const initSql = fs.readFileSync(path.join(__dirname, 'src/migrations/init.sql'), 'utf8');
        await pool.query(initSql);
        console.log('✅ Base de datos lista.');
    } catch (err) {
        console.error('❌ Error en configuración de BD:', err);
    }
};
runMigrations();

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
    let { nombre, email, password } = req.body;
    if (!nombre || !email || !password) return res.status(400).json({ error: "Datos incompletos" });
    const cleanEmail = email.trim().toLowerCase();
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        const result = await pool.query(
            'INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3) RETURNING id',
            [nombre.trim(), cleanEmail, hashedPassword]
        );
        res.status(201).json({ message: "OK", userId: result.rows[0].id });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.post('/api/auth/login', async (req, res) => {
    let { email, password } = req.body;
    const cleanEmail = email.trim().toLowerCase();
    try {
        const { rows } = await pool.query('SELECT * FROM usuarios WHERE email = $1', [cleanEmail]);
        if (rows.length === 0) return res.status(401).json({ error: "No existe" });
        const valid = await bcrypt.compare(password, rows[0].password);
        if (!valid) return res.status(401).json({ error: "Password mal" });
        const token = jwt.sign({ userId: rows[0].id, nombre: rows[0].nombre }, JWT_SECRET, { expiresIn: '7d' });
        const { password: _, ...usuarioSeguro } = rows[0];
        res.json({ token, usuario: usuarioSeguro });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- LUGARES CON OPENSTREETMAP ---
app.get('/api/lugares', async (req, res) => {
    const { lat, lng } = req.query;
    console.log(`[OSM] Buscando restaurantes cerca de: ${lat}, ${lng}`);

    // Query para Cali, Colombia (Área aproximada)
    const overpassQuery = `
        [out:json][timeout:25];
        (
          node["amenity"="restaurant"](3.30,-76.60,3.55,-76.40);
          node["amenity"="cafe"](3.30,-76.60,3.55,-76.40);
        );
        out body;
    `;

    try {
        const response = await axios.post('https://overpass-api.de/api/interpreter', overpassQuery);

        let restaurantes = response.data.elements.map((e, index) => {
            const rLat = e.lat;
            const rLng = e.lon;
            let distInfo = null;

            if (lat && lng) {
                const d = calcularDistancia(parseFloat(lat), parseFloat(lng), rLat, rLng);
                distInfo = calcularTiempos(d);
            }

            return {
                id: e.id || index + 100,
                nombre: e.tags.name || "Restaurante Cali",
                categoria: e.tags.amenity === 'cafe' ? 'Café' : 'Restaurante',
                precio: e.tags.price || "$$",
                rating: 4.0 + (Math.random() * 1), // Rating simulado para OSM
                descripcion: e.tags.cuisine ? `Cocina: ${e.tags.cuisine}` : "Restaurante típico en Cali.",
                imagen_url: `https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?sig=${e.id}`,
                lat: rLat,
                lng: rLng,
                distancia_info: distInfo
            };
        });

        // Fallback si OSM no devuelve nada
        if (restaurantes.length === 0) {
            restaurantes = [
                { id: 1, nombre: "Restaurante Granada", categoria: "Restaurante", rating: 4.8, lat: 3.4516, lng: -76.5320 },
                { id: 2, nombre: "Sabor Caleño", categoria: "Típico", rating: 4.5, lat: 3.4480, lng: -76.5350 }
            ];
        }

        res.json(restaurantes);
    } catch (error) {
        console.error("Error OSM:", error.message);
        res.json([
            { id: 99, nombre: "Restaurante Fallback", categoria: "Local", rating: 4.0, lat: 3.44, lng: -76.52 }
        ]);
    }
});

app.get('/api/lugares/cercanos', async (req, res) => {
    // Reutilizamos la lógica de lugares para simplificar
    return app._router.handle({ method: 'get', url: '/api/lugares', query: req.query }, res);
});

app.listen(PORT, () => console.log(`🚀 Servidor en puerto ${PORT}`));
