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

        // Asegurar que exista la columna foto_url en usuarios
        await pool.query('ALTER TABLE usuarios ADD COLUMN IF NOT EXISTS foto_url TEXT');

        // Asegurar tabla lugares con columnas correctas
        await pool.query(`
            CREATE TABLE IF NOT EXISTS lugares (
                id SERIAL PRIMARY KEY,
                nombre TEXT NOT NULL,
                descripcion TEXT,
                imagen TEXT,
                rating FLOAT DEFAULT 0.0,
                precio TEXT,
                latitud DOUBLE PRECISION,
                longitud DOUBLE PRECISION,
                direccion TEXT,
                como_llegar TEXT
            )
        `);

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

// --- ADMIN SEED ---
app.post('/api/admin/seed', async (req, res) => {
    const adminKey = req.headers['x-admin-key'];
    if (adminKey !== '12345') {
        return res.status(403).json({ error: 'No autorizado' });
    }

    try {
        const checkResult = await pool.query('SELECT COUNT(*) FROM lugares');
        const count = parseInt(checkResult.rows[0].count);

        if (count > 0) {
            return res.status(400).json({
                message: 'La tabla ya tiene datos. Seed cancelado.',
                total_registros: count
            });
        }

        const restaurantes = [
            ['Restaurante Como en Casa', 'Almuerzos caseros económicos para estudiantes.', 'https://images.unsplash.com/photo-1551218808-94e220e084d2', 4.5, '$', 3.4520, -76.5315, 'Pampalinda, Cali', 'https://www.google.com/maps/dir/?api=1&destination=3.4520,-76.5315'],
            ['El Paso Hamburguesas', 'Hamburguesas grandes y deliciosas.', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd', 4.3, '$$', 3.4505, -76.5330, 'Calle 9, Cali', 'https://www.google.com/maps/dir/?api=1&destination=3.4505,-76.5330'],
            ['La Arepería', 'Arepas rellenas y comida rápida.', 'https://images.unsplash.com/photo-1604908176997-125f25cc6f3d', 4.2, '$', 3.4510, -76.5325, 'Zona universitaria', 'https://www.google.com/maps/dir/?api=1&destination=3.4510,-76.5325'],
            ['Food Lovers', 'Comida urbana moderna.', 'https://images.unsplash.com/photo-1555992336-03a23c9e7b8d', 4.7, '$$$', 3.4530, -76.5340, 'Cali Sur', 'https://www.google.com/maps/dir/?api=1&destination=3.4530,-76.5340'],
            ['La Vecindad', 'Comida rápida y económica.', 'https://images.unsplash.com/photo-1550547660-d9450f859349', 4.4, '$', 3.4525, -76.5335, 'Calle 6, Cali', 'https://www.google.com/maps/dir/?api=1&destination=3.4525,-76.5335'],
            ['La Sazón del Valle', 'Comida típica vallecaucana.', 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c', 4.6, '$$', 3.4518, -76.5310, 'Pampalinda', 'https://www.google.com/maps/dir/?api=1&destination=3.4518,-76.5310'],
            ['Burger House Cali', 'Hamburguesas artesanales.', 'https://images.unsplash.com/photo-1550547660-d9450f859349', 4.3, '$$', 3.4508, -76.5328, 'Cerca a la USC', 'https://www.google.com/maps/dir/?api=1&destination=3.4508,-76.5328'],
            ['Pizza Urbana', 'Pizzas artesanales al horno.', 'https://images.unsplash.com/photo-1548365328-9f547fb0953c', 4.5, '$$', 3.4512, -76.5332, 'Pampalinda', 'https://www.google.com/maps/dir/?api=1&destination=3.4512,-76.5332'],
            ['Pollo Express USC', 'Pollo frito y combos económicos.', 'https://images.unsplash.com/photo-1600891964599-f61ba0e24092', 4.1, '$', 3.4523, -76.5322, 'Zona USC', 'https://www.google.com/maps/dir/?api=1&destination=3.4523,-76.5322'],
            ['Café Pampalinda', 'Café, postres y snacks.', 'https://images.unsplash.com/photo-1509042239860-f550ce710b93', 4.6, '$', 3.4515, -76.5318, 'Cerca universidad', 'https://www.google.com/maps/dir/?api=1&destination=3.4515,-76.5318'],
            ['Tacos Cali', 'Tacos mexicanos y comida rápida.', 'https://images.unsplash.com/photo-1600891963934-06c3f4c81e0e', 4.4, '$$', 3.4509, -76.5338, 'Zona sur Cali', 'https://www.google.com/maps/dir/?api=1&destination=3.4509,-76.5338'],
            ['Sushi Cali Express', 'Sushi fresco y económico.', 'https://images.unsplash.com/photo-1562158070-57a3b5f3e5e6', 4.7, '$$$', 3.4527, -76.5345, 'Cali Sur', 'https://www.google.com/maps/dir/?api=1&destination=3.4527,-76.5345'],
            ['Panadería Estudiantil', 'Panadería, deasyunos y jugos.', 'https://images.unsplash.com/photo-1509440159596-0249088772ff', 4.3, '$', 3.4513, -76.5312, 'Zona USC', 'https://www.google.com/maps/dir/?api=1&destination=3.4513,-76.5312'],
            ['Parrilla Urbana', 'Carnes a la parrilla y combos.', 'https://images.unsplash.com/photo-1558036117-15d82a90b9b1', 4.6, '$$$', 3.4535, -76.5333, 'Sur de Cali', 'https://www.google.com/maps/dir/?api=1&destination=3.4535,-76.5333'],
            ['Comidas Rápidas USC', 'Hot dogs, papas y combos.', 'https://images.unsplash.com/photo-1550547660-d9450f859349', 4.2, '$', 3.4507, -76.5319, 'Zona universitaria', 'https://www.google.com/maps/dir/?api=1&destination=3.4507,-76.5319']
        ];

        const queryText = `
            INSERT INTO lugares (nombre, descripcion, imagen, rating, precio, latitud, longitud, direccion, como_llegar)
            VALUES ${restaurantes.map((_, i) => `($${i * 9 + 1}, $${i * 9 + 2}, $${i * 9 + 3}, $${i * 9 + 4}, $${i * 9 + 5}, $${i * 9 + 6}, $${i * 9 + 7}, $${i * 9 + 8}, $${i * 9 + 9})`).join(', ')}
        `;

        await pool.query(queryText, restaurantes.flat());
        res.status(201).json({ message: 'Seed completado' });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// --- AUTH ---
app.post('/api/auth/register', async (req, res) => {
    let { nombre, email, password } = req.body;
    if (!nombre || !email || !password) return res.status(400).json({ error: "Requeridos" });
    const cleanEmail = email.trim().toLowerCase();
    try {
        const hashedPassword = await bcrypt.hash(password.trim(), 10);
        const result = await pool.query(
            'INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3) RETURNING id, nombre, email',
            [nombre.trim(), cleanEmail, hashedPassword]
        );
        res.status(201).json({ usuario: result.rows[0] });
    } catch (err) {
        res.status(500).json({ error: err.message });
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
        res.json({ token, usuario: rows[0] });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- LUGARES ---
app.get('/api/lugares', async (req, res) => {
    try {
        const { rows } = await pool.query('SELECT * FROM lugares ORDER BY id ASC');
        res.json(rows);
    } catch (err) { res.status(500).json({ error: err.message }); }
});

app.get('/api/lugares/cercanos', async (req, res) => {
    return app._router.handle({ method: 'get', url: '/api/lugares', query: req.query }, res);
});

app.get('/api/lugares/:id', async (req, res) => {
    try {
        const lugarRes = await pool.query('SELECT * FROM lugares WHERE id = $1', [req.params.id]);
        if (lugarRes.rows.length === 0) return res.status(404).json({ error: "No encontrado" });
        const resenasRes = await pool.query(
            'SELECT r.*, u.nombre as usuario_nombre FROM resenas r JOIN usuarios u ON r.usuario_id = u.id WHERE r.lugar_id = $1 ORDER BY r.fecha DESC',
            [req.params.id]
        );
        res.json({
            ...lugarRes.rows[0],
            promedio_rating: lugarRes.rows[0].rating,
            total_resenas: resenasRes.rows.length,
            resenas: resenasRes.rows
        });
    } catch (err) { res.status(500).json({ error: err.message }); }
});

// --- ADMIN: RESET DB ---
app.post('/api/admin/reset-db', async (req, res) => {
    try {
        // Limpiar datos existentes respetando las FK
        await pool.query('DELETE FROM favoritos');
        await pool.query('DELETE FROM resenas');
        await pool.query('DELETE FROM lugares');

        // Insertar los 15 restaurantes reales de Cali desde seed.sql
        const seedSql = fs.readFileSync(path.join(__dirname, 'src/migrations/seed.sql'), 'utf8');
        await pool.query(seedSql);

        const { rows } = await pool.query('SELECT COUNT(*) FROM lugares');
        res.json({
            message: '✅ Base de datos reiniciada con los 15 restaurantes de Cali',
            total_lugares: parseInt(rows[0].count)
        });
    } catch (err) {
        console.error('❌ Error en reset-db:', err);
        res.status(500).json({ error: 'Error al reiniciar la base de datos', detalle: err.message });
    }
});

app.listen(PORT, () => console.log(`🚀 Servidor en puerto ${PORT}`));
