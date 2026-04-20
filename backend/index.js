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

        // Verificar columnas faltantes
        await pool.query("ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS foto_url TEXT DEFAULT NULL;");

        // Asegurar que el usuario admin siempre exista
        const hashedAdminPass = await bcrypt.hash('123456', 10);
        const adminCheck = await pool.query('SELECT * FROM usuarios WHERE email = $1', ['admin@admin.com']);

        if (adminCheck.rows.length === 0) {
            await pool.query(
                'INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3)',
                ['Administrador', 'admin@admin.com', hashedAdminPass]
            );
            console.log('✅ Usuario admin creado.');
        } else {
            await pool.query(
                'UPDATE usuarios SET password = $1 WHERE email = $2',
                [hashedAdminPass, 'admin@admin.com']
            );
        }

        console.log('✅ Base de datos lista.');
        const { rows } = await pool.query("SELECT COUNT(*) FROM lugares");
        if (parseInt(rows[0].count) === 0) {
            const seedSql = `
                INSERT INTO lugares (nombre, categoria, precio, price_level, rating, distancia, descripcion, imagen_url, lat, lng) VALUES
                ('Restaurante Bella Vista', 'Restaurante', '$$', 'Caro', 4.5, '1.2km', 'Cocina local e internacional con terraza y vista panorámica.', 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4', 3.4516, -76.5320),
                ('Café Aroma', 'Cafés', '$', 'Economico', 4.2, '800m', 'Café de especialidad y panadería artesanal.', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93', 3.4520, -76.5310),
                ('Bar La Cima', 'Discotecas', '$$$', 'Caro', 3.8, '2.1km', 'Coctelería creativa y música en vivo los fines de semana.', 'https://images.unsplash.com/photo-1514525253361-bee8d4206d9b', 3.4530, -76.5300),
                ('Burger House', 'Restaurante', '$', 'Economico', 4.7, '500m', 'Las mejores hamburguesas artesanales de la ciudad.', 'https://images.unsplash.com/photo-1571091718767-18b5b1457add', 3.4400, -76.5200),
                ('Museo de la Ciudad', 'Cultura', 'Gratis', 'Economico', 4.9, '1.5km', 'Historia y arte local en un edificio colonial.', 'https://images.unsplash.com/photo-1518998053502-531ed392138c', 3.4500, -76.5400),
                ('Parque Central', 'Naturaleza', 'Gratis', 'Economico', 4.6, '300m', 'El pulmón verde de la ciudad para pasear.', 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e', 3.4550, -76.5350);
            `;
            await pool.query(seedSql);
        }

        // Forzar usuario de prueba admin@admin.com / 123456
        const hashedAdminPass = await bcrypt.hash('123456', 10);
        const adminCheck = await pool.query('SELECT * FROM usuarios WHERE email = $1', ['admin@admin.com']);

        if (adminCheck.rows.length === 0) {
            await pool.query(
                'INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3)',
                ['Administrador', 'admin@admin.com', hashedAdminPass]
            );
            console.log('✅ Usuario admin creado por primera vez.');
        } else {
            await pool.query(
                'UPDATE usuarios SET password = $1, nombre = $2 WHERE email = $3',
                [hashedAdminPass, 'Administrador', 'admin@admin.com']
            );
            console.log('✅ Contraseña de admin actualizada a 123456.');
        }

        console.log('✅ Base de datos verificada y actualizada.');
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

// Rutas duplicadas para compatibilidad (con y sin /api)
app.post('/api/auth/register', handleRegister);
app.post('/auth/register', handleRegister);
app.post('/api/auth/login', handleLogin);
app.post('/auth/login', handleLogin);

async function handleRegister(req, res) {
    let { nombre, email, password } = req.body;
    if (!nombre || !email || !password) return res.status(400).json({ error: "Datos incompletos" });
    const cleanEmail = email.trim().toLowerCase();
    try {
        console.log(`[AUTH] Intentando registrar: ${cleanEmail}`);
        const check = await pool.query('SELECT id FROM usuarios WHERE email = $1', [cleanEmail]);
        if (check.rows.length > 0) return res.status(400).json({ error: "Email ya registrado" });
        const hashedPassword = await bcrypt.hash(password, 10);
        const result = await pool.query(
            'INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3) RETURNING id',
            [nombre.trim(), cleanEmail, hashedPassword]
        );
        console.log(`[AUTH] ✅ Usuario creado ID: ${result.rows[0].id}`);
        res.status(201).json({ message: "OK", userId: result.rows[0].id });
    } catch (err) {
        console.error("[AUTH] ❌ Error:", err.message);
        res.status(500).json({ error: err.message });
    }
}

async function handleLogin(req, res) {
    let { email, password } = req.body;
    if (!email || !password) return res.status(400).json({ error: "Faltan datos" });
    const cleanEmail = email.trim().toLowerCase();
    try {
        console.log(`[AUTH] Intento login: ${cleanEmail}`);
        const { rows } = await pool.query('SELECT * FROM usuarios WHERE email = $1', [cleanEmail]);
        if (rows.length === 0) return res.status(401).json({ error: "No existe" });

        const valid = await bcrypt.compare(password, rows[0].password);
        if (!valid) return res.status(401).json({ error: "Password mal" });

        const token = jwt.sign({ userId: rows[0].id, nombre: rows[0].nombre }, JWT_SECRET, { expiresIn: '7d' });

        // Fix Bug #3: No devolver la contraseña
        const { password: _, ...usuarioSeguro } = rows[0];

        res.json({
            token,
            usuario: usuarioSeguro
        });
    } catch (err) {
        console.error("[AUTH] ❌ Error login:", err.message);
        res.status(500).json({ error: err.message });
    }
}

// --- LUGARES ---
app.get('/api/lugares', async (req, res) => {
    const { lat, lng } = req.query;
    try {
        const { rows } = await pool.query('SELECT * FROM lugares ORDER BY rating DESC');
        const results = rows.map(lugar => {
            let distancia_info = null;
            if (lat && lng) {
                const dist = calcularDistancia(parseFloat(lat), parseFloat(lng), lugar.lat, lugar.lng);
                distancia_info = calcularTiempos(dist);
            }
            return { ...lugar, distancia_info };
        });
        res.json(results);
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

app.get('/api/lugares/buscar', async (req, res) => {
    const { q, lat, lng } = req.query;
    try {
        let queryText = 'SELECT * FROM lugares WHERE 1=1';
        let queryParams = [];
        if (q) {
            queryText += ' AND (nombre ILIKE $1 OR categoria ILIKE $1 OR descripcion ILIKE $1)';
            queryParams.push(`%${q}%`);
        }
        queryText += ' ORDER BY rating DESC';

        const { rows } = await pool.query(queryText, queryParams);
        const results = rows.map(lugar => {
            let distancia_info = null;
            if (lat && lng) {
                const dist = calcularDistancia(parseFloat(lat), parseFloat(lng), lugar.lat, lugar.lng);
                distancia_info = calcularTiempos(dist);
            }
            return { ...lugar, distancia_info };
        });
        res.json(results);
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

app.get('/api/lugares/cercanos', async (req, res) => {
    const { lat, lng } = req.query;
    if (!lat || !lng) return res.status(400).json({ error: "Lat y lng requeridos" });
    try {
        const { rows } = await pool.query('SELECT * FROM lugares');
        const results = rows.map(lugar => {
            const dist = calcularDistancia(parseFloat(lat), parseFloat(lng), lugar.lat, lugar.lng);
            return { ...lugar, distancia_info: calcularTiempos(dist) };
        }).filter(l => l.distancia_info.distancia_km <= 5)
          .sort((a, b) => a.distancia_info.distancia_km - b.distancia_info.distancia_km);
        res.json(results);
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

app.get('/api/lugares/google-cercanos', async (req, res) => {
    const { lat, lng } = req.query;
    const API_KEY = process.env.GOOGLE_PLACES_API_KEY;
    if (!lat || !lng) return res.status(400).json({ error: "Lat y lng requeridos" });
    if (!API_KEY) return res.status(500).json({ error: "API Key no configurada" });
    try {
        const url = `https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=${lat},${lng}&radius=2000&key=${API_KEY}`;
        const response = await axios.get(url);
        const places = response.data.results.map(p => {
            const dist = calcularDistancia(parseFloat(lat), parseFloat(lng), p.geometry.location.lat, p.geometry.location.lng);
            return {
                id: p.place_id,
                nombre: p.name,
                categoria: p.types[0],
                rating: p.rating || 0,
                lat: p.geometry.location.lat,
                lng: p.geometry.location.lng,
                imagenUrl: p.photos
                    ? `https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=${p.photos[0].photo_reference}&key=${API_KEY}`
                    : 'https://via.placeholder.com/400',
                distancia_info: calcularTiempos(dist),
                esGoogle: true
            };
        });
        res.json(places);
    } catch (err) { res.status(500).json({ error: "Error Google Places" }); }
});

app.get('/api/lugares/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const lugar = await pool.query('SELECT * FROM lugares WHERE id = $1', [id]);
        if (lugar.rows.length === 0) return res.status(404).json({ error: "No encontrado" });
        const resenas = await pool.query(
            'SELECT r.id, r.comentario, r.rating, r.fecha, u.nombre as usuario_nombre, u.id as usuario_id FROM resenas r JOIN usuarios u ON r.usuario_id = u.id WHERE r.lugar_id = $1 ORDER BY r.fecha DESC',
            [id]
        );
        res.json({ ...lugar.rows[0], resenas: resenas.rows });
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

// --- RESEÑAS ---
app.post('/api/resenas', authenticateToken, async (req, res) => {
    const { lugar_id, comentario, rating } = req.body;
    try {
        const result = await pool.query(
            'INSERT INTO resenas (lugar_id, usuario_id, comentario, rating) VALUES ($1, $2, $3, $4) RETURNING *',
            [lugar_id, req.user.userId, comentario, rating || 5]
        );
        res.status(201).json({ message: "Reseña guardada", resena: result.rows[0] });
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

app.put('/api/resenas/:id', authenticateToken, async (req, res) => {
    const { comentario, rating } = req.body;
    try {
        const check = await pool.query('SELECT usuario_id FROM resenas WHERE id = $1', [req.params.id]);
        if (check.rows.length === 0) return res.status(404).json({ error: "Reseña no encontrada" });
        if (check.rows[0].usuario_id !== req.user.userId) return res.status(403).json({ error: "No autorizado" });

        const result = await pool.query(
            'UPDATE resenas SET comentario = COALESCE($1, comentario), rating = COALESCE($2, rating) WHERE id = $3 RETURNING *',
            [comentario, rating, req.params.id]
        );
        res.json({ message: "Reseña actualizada", resena: result.rows[0] });
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

app.delete('/api/resenas/:id', authenticateToken, async (req, res) => {
    try {
        const check = await pool.query('SELECT usuario_id FROM resenas WHERE id = $1', [req.params.id]);
        if (check.rows.length === 0) return res.status(404).json({ error: "No encontrada" });
        if (check.rows[0].usuario_id !== req.user.userId) return res.status(403).json({ error: "No autorizado" });

        await pool.query('DELETE FROM resenas WHERE id = $1', [req.params.id]);
        res.json({ message: "Reseña eliminada" });
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

// --- FAVORITOS ---
app.get('/api/favoritos', authenticateToken, async (req, res) => {
    try {
        const { rows } = await pool.query(
            'SELECT l.* FROM lugares l JOIN favoritos f ON l.id = f.lugar_id WHERE f.usuario_id = $1',
            [req.user.userId]
        );
        res.json(rows);
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

app.post('/api/favoritos/toggle', authenticateToken, async (req, res) => {
    const { lugar_id } = req.body;
    try {
        const exist = await pool.query('SELECT * FROM favoritos WHERE usuario_id = $1 AND lugar_id = $2', [req.user.userId, lugar_id]);
        if (exist.rows.length > 0) {
            await pool.query('DELETE FROM favoritos WHERE usuario_id = $1 AND lugar_id = $2', [req.user.userId, lugar_id]);
            return res.json({ favorito: false });
        }
        await pool.query('INSERT INTO favoritos (usuario_id, lugar_id) VALUES ($1, $2)', [req.user.userId, lugar_id]);
        res.json({ favorito: true });
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

app.get('/api/favoritos/check/:id', authenticateToken, async (req, res) => {
    try {
        const { rows } = await pool.query('SELECT * FROM favoritos WHERE usuario_id = $1 AND lugar_id = $2', [req.user.userId, req.params.id]);
        res.json({ esFavorito: rows.length > 0 });
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

// --- USUARIOS ---
app.get('/api/usuarios/perfil', authenticateToken, async (req, res) => {
    try {
        const { rows } = await pool.query('SELECT id, nombre, email, foto_url, creado_en FROM usuarios WHERE id = $1', [req.user.userId]);
        res.json(rows[0]);
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

app.put('/api/usuarios/perfil', authenticateToken, async (req, res) => {
    const { nombre, email, password_actual, password_nueva, foto_url } = req.body;
    try {
        const user = (await pool.query('SELECT * FROM usuarios WHERE id = $1', [req.user.userId])).rows[0];

        if (password_nueva) {
            if (!password_actual || !(await bcrypt.compare(password_actual, user.password))) {
                return res.status(401).json({ error: "Contraseña actual incorrecta" });
            }
            const hash = await bcrypt.hash(password_nueva, 10);
            await pool.query('UPDATE usuarios SET password = $1 WHERE id = $2', [hash, req.user.userId]);
        }

        const result = await pool.query(
            'UPDATE usuarios SET nombre = COALESCE($1, nombre), email = COALESCE($2, email), foto_url = COALESCE($3, foto_url) WHERE id = $4 RETURNING id, nombre, email, foto_url',
            [nombre, email, foto_url, req.user.userId]
        );
        res.json({ message: "Perfil actualizado", usuario: result.rows[0] });
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

app.get('/api/usuarios/estadisticas', authenticateToken, async (req, res) => {
    try {
        const resenas = await pool.query('SELECT COUNT(*) FROM resenas WHERE usuario_id = $1', [req.user.userId]);
        const favoritos = await pool.query('SELECT COUNT(*) FROM favoritos WHERE usuario_id = $1', [req.user.userId]);
        const user = await pool.query('SELECT creado_en FROM usuarios WHERE id = $1', [req.user.userId]);
        res.json({
            total_resenas: parseInt(resenas.rows[0].count),
            total_favoritos: parseInt(favoritos.rows[0].count),
            miembro_desde: user.rows[0].creado_en
        });
    } catch (err) { res.status(500).json({ error: "Error" }); }
});

app.get('/db-status', async (req, res) => {
    try {
        await pool.query('SELECT 1');
        res.json({ status: "Online", database: "Connected" });
    } catch (err) { res.status(500).json({ status: "Error", message: err.message }); }
});

app.get('/', (req, res) => res.json({ mensaje: "API de DescubreMiCiudad conectada a Postgres Online", status: "Online" }));

app.listen(PORT, () => console.log(`🚀 Servidor en puerto ${PORT}`));
