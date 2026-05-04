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

        // Asegurar que exista la columna foto_url
        await pool.query('ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS foto_url TEXT');

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
    
    // Validar campos requeridos
    if (!nombre || !email || !password) {
        return res.status(400).json({ error: "Nombre, email y contraseña son requeridos" });
    }
    
    const cleanEmail = email.trim().toLowerCase();
    
    // Validar formato de email
    const emailRegex = /^[\w\.-]+@[\w\.-]+\.\w+$/;
    if (!emailRegex.test(cleanEmail)) {
        return res.status(400).json({ error: "Formato de email inválido" });
    }
    
    // Validar longitud de contraseña
    if (password.trim().length < 6) {
        return res.status(400).json({ error: "La contraseña debe tener mínimo 6 caracteres" });
    }
    
    try {
        const hashedPassword = await bcrypt.hash(password.trim(), 10);
        const result = await pool.query(
            'INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3) RETURNING id, nombre, email',
            [nombre.trim(), cleanEmail, hashedPassword]
        );
        res.status(201).json({ 
            message: "Usuario creado exitosamente", 
            userId: result.rows[0].id,
            usuario: result.rows[0]
        });
    } catch (err) {
        // Manejo específico de errores de PostgreSQL
        if (err.code === '23505') { // Constraint violation (duplicate key)
            res.status(400).json({ error: "Este email ya está registrado" });
        } else if (err.code === '23502') { // Not null violation
            res.status(400).json({ error: "Todos los campos son requeridos" });
        } else {
            console.error('Error en registro:', err);
            res.status(500).json({ error: "Error al registrar usuario. Intenta más tarde." });
        }
    }
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

    // Query para Cali, Colombia (Solo restaurantes reales)
    const overpassQuery = `
        [out:json][timeout:25];
        (
          node["amenity"="restaurant"](3.30,-76.60,3.55,-76.40);
        );
        out body;
    `;

    try {
        const response = await axios.post('https://overpass-api.de/api/interpreter', overpassQuery);

        let restaurantes = response.data.elements
            .filter(e => e.tags && e.tags.name) // Solo los que tienen nombre
            .map((e, index) => {
            const rLat = e.lat;
            const rLng = e.lon;
            let distInfo = null;

            if (lat && lng) {
                const d = calcularDistancia(parseFloat(lat), parseFloat(lng), rLat, rLng);
                distInfo = calcularTiempos(d);
            }

            const keywords = ['restaurant', 'food', 'steak', 'pizza', 'gourmet', 'dinner'];
            const randomKeyword = keywords[index % keywords.length];

            return {
                id: e.id || index + 100,
                nombre: e.tags.name,
                categoria: 'Restaurante',
                precio: e.tags.price || "$$",
                rating: 4.0 + (Math.random() * 0.9), // Rating más realista entre 4.0 y 4.9
                descripcion: e.tags.cuisine ? `Cocina: ${e.tags.cuisine}` : "Excelente restaurante en Cali.",
                imagen_url: `https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?sig=${index + 100}`,
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

app.get('/api/lugares/:id', async (req, res) => {
    try {
        const lugarRes = await pool.query('SELECT * FROM lugares WHERE id = $1', [req.params.id]);
        if (lugarRes.rows.length === 0) return res.status(404).json({ error: "Lugar no encontrado" });

        const resenasRes = await pool.query(
            'SELECT r.*, u.nombre as usuario_nombre FROM resenas r JOIN usuarios u ON r.usuario_id = u.id WHERE r.lugar_id = $1 ORDER BY r.fecha DESC',
            [req.params.id]
        );

        // Calcular promedio y total para que el frontend lo muestre correctamente
        const totalResenas = resenasRes.rows.length;
        const promedioCalificacion = totalResenas > 0
            ? (resenasRes.rows.reduce((acc, r) => acc + r.rating, 0) / totalResenas).toFixed(1)
            : lugarRes.rows[0].rating;

        res.json({
            ...lugarRes.rows[0],
            promedioCalificacion: parseFloat(promedioCalificacion),
            totalResenas: totalResenas,
            resenas: resenasRes.rows
        });
    } catch (err) {
        res.status(500).json({ error: "Error al obtener detalles" });
    }
});

// --- PERFIL DE USUARIO ---
app.get('/api/usuarios/perfil', authenticateToken, async (req, res) => {
    try {
        const { rows } = await pool.query('SELECT id, nombre, email, foto_url, creado_en FROM usuarios WHERE id = $1', [req.user.userId]);
        if (rows.length === 0) return res.status(404).json({ error: "Usuario no encontrado" });
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: "Error al obtener perfil" });
    }
});

app.put('/api/usuarios/perfil', authenticateToken, async (req, res) => {
    const { nombre, email, foto_url, password_actual, password_nueva } = req.body;
    try {
        // Si hay cambio de password, verificar la actual
        if (password_nueva) {
            const { rows } = await pool.query('SELECT password FROM usuarios WHERE id = $1', [req.user.userId]);
            const valid = await bcrypt.compare(password_actual, rows[0].password);
            if (!valid) return res.status(401).json({ error: "Contraseña actual incorrecta" });

            const hashedNew = await bcrypt.hash(password_nueva, 10);
            await pool.query('UPDATE usuarios SET password = $1 WHERE id = $2', [hashedNew, req.user.userId]);
        }

        await pool.query(
            'UPDATE usuarios SET nombre = COALESCE($1, nombre), email = COALESCE($2, email), foto_url = COALESCE($3, foto_url) WHERE id = $4',
            [nombre, email, foto_url, req.user.userId]
        );
        res.json({ message: "Perfil actualizado correctamente" });
    } catch (err) {
        res.status(500).json({ error: "Error al actualizar perfil" });
    }
});

// --- FAVORITOS ---
app.post('/api/favoritos', authenticateToken, async (req, res) => {
    const { lugar_id } = req.body;
    try {
        await pool.query(
            'INSERT INTO favoritos (usuario_id, lugar_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
            [req.user.userId, lugar_id]
        );
        res.json({ message: "Agregado a favoritos" });
    } catch (err) {
        res.status(500).json({ error: "Error al agregar favorito" });
    }
});

app.delete('/api/favoritos/:lugarId', authenticateToken, async (req, res) => {
    try {
        await pool.query(
            'DELETE FROM favoritos WHERE usuario_id = $1 AND lugar_id = $2',
            [req.user.userId, req.params.lugarId]
        );
        res.json({ message: "Eliminado de favoritos" });
    } catch (err) {
        res.status(500).json({ error: "Error al eliminar favorito" });
    }
});

app.get('/api/favoritos', authenticateToken, async (req, res) => {
    try {
        const { rows } = await pool.query(
            'SELECT f.*, l.nombre, l.imagen_url FROM favoritos f JOIN lugares l ON f.lugar_id = l.id WHERE f.usuario_id = $1',
            [req.user.userId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: "Error al obtener favoritos" });
    }
});

// --- RESEÑAS Y RATING ---
app.post('/api/resenas', authenticateToken, async (req, res) => {
    const { lugar_id, comentario, rating } = req.body;
    try {
        const { rows } = await pool.query(
            `INSERT INTO resenas (usuario_id, lugar_id, comentario, rating)
             VALUES ($1, $2, $3, $4)
             ON CONFLICT (usuario_id, lugar_id)
             DO UPDATE SET comentario = $3, rating = $4, fecha = NOW()
             RETURNING *`,
            [req.user.userId, lugar_id, comentario, rating]
        );
        res.json(rows[0]);
    } catch (err) {
        res.status(500).json({ error: "Error al publicar reseña" });
    }
});

app.get('/api/resenas/:lugarId', async (req, res) => {
    try {
        const { rows } = await pool.query(
            'SELECT r.*, u.nombre as usuario_nombre FROM resenas r JOIN usuarios u ON r.usuario_id = u.id WHERE r.lugar_id = $1 ORDER BY r.fecha DESC',
            [req.params.lugarId]
        );
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: "Error al obtener reseñas" });
    }
});

app.listen(PORT, () => console.log(`🚀 Servidor en puerto ${PORT}`));
