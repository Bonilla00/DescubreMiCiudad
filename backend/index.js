const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'mi_secreto_super_seguro';

// Configuración de la conexión a Postgres
const pool = new Pool({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false
    }
});

app.use(cors());
app.use(express.json());

// --- MIGRACIONES Y SEED ---
const runMigrations = async () => {
    try {
        const initSql = fs.readFileSync(path.join(__dirname, 'src/migrations/init.sql'), 'utf8');
        const seedSql = fs.readFileSync(path.join(__dirname, 'src/migrations/seed.sql'), 'utf8');

        await pool.query(initSql);
        console.log('✅ Tablas verificadas/creadas.');

        // Verificar si ya hay datos para no duplicar seed si no tiene ON CONFLICT
        const { rows } = await pool.query('SELECT COUNT(*) FROM lugares');
        if (parseInt(rows[0].count) === 0) {
            await pool.query(seedSql);
            console.log('✅ Datos iniciales insertados.');
        }
    } catch (err) {
        console.error('❌ Error en migraciones:', err);
    }
};

runMigrations();

// --- MIDDLEWARE JWT ---
const authenticateToken = (req, res, next) => {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (!token) return res.status(401).json({ error: "Token requerido" });

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ error: "Token inválido o expirado" });
        req.user = user;
        next();
    });
};

// --- RUTAS ---

// 1. Auth: Registro
app.post('/api/auth/register', async (req, res) => {
    const { nombre, email, password } = req.body;
    try {
        const hashedPassword = await bcrypt.hash(password, 10);
        const result = await pool.query(
            'INSERT INTO usuarios (nombre, email, password) VALUES ($1, $2, $3) RETURNING id',
            [nombre, email, hashedPassword]
        );
        res.status(201).json({ message: "Usuario creado", userId: result.rows[0].id });
    } catch (err) {
        if (err.code === '23505') {
            return res.status(400).json({ error: "Email ya registrado" });
        }
        res.status(500).json({ error: "Error en el servidor" });
    }
});

// 2. Auth: Login
app.post('/api/auth/login', async (req, res) => {
    const { email, password } = req.body;
    try {
        const { rows } = await pool.query('SELECT * FROM usuarios WHERE email = $1', [email]);
        if (rows.length === 0) return res.status(401).json({ error: "Credenciales incorrectas" });

        const user = rows[0];
        const validPass = await bcrypt.compare(password, user.password);
        if (!validPass) return res.status(401).json({ error: "Credenciales incorrectas" });

        const token = jwt.sign({ userId: user.id, email: user.email }, JWT_SECRET, { expiresIn: '7d' });
        res.json({
            token,
            usuario: { id: user.id, nombre: user.nombre, email: user.email }
        });
    } catch (err) {
        res.status(500).json({ error: "Error en el servidor" });
    }
});

// 3. Lugares: Listar todos
app.get('/api/lugares', async (req, res) => {
    try {
        const { rows } = await pool.query('SELECT * FROM lugares ORDER BY rating DESC');
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: "Error al obtener lugares" });
    }
});

// 4. Lugares: Buscar y Filtrar
app.get('/api/lugares/buscar', async (req, res) => {
    const { q, categoria, precio } = req.query;
    let query = 'SELECT * FROM lugares WHERE 1=1';
    const params = [];

    if (q) {
        params.push(`%${q}%`);
        query += ` AND nombre ILIKE $${params.length}`;
    }
    if (categoria) {
        params.push(categoria);
        query += ` AND categoria = $${params.length}`;
    }
    if (precio) {
        params.push(precio); // El prompt dice precio=Y pero pide filtrar por price_level
        query += ` AND price_level = $${params.length}`;
    }

    try {
        const { rows } = await pool.query(query, params);
        res.json(rows);
    } catch (err) {
        res.status(500).json({ error: "Error en la búsqueda" });
    }
});

// 5. Lugares: Detalle + Reseñas
app.get('/api/lugares/:id', async (req, res) => {
    const { id } = req.params;
    try {
        const lugarRes = await pool.query('SELECT * FROM lugares WHERE id = $1', [id]);
        if (lugarRes.rows.length === 0) return res.status(404).json({ error: "Lugar no encontrado" });

        const resenasRes = await pool.query(
            `SELECT r.*, u.nombre as usuario_nombre
             FROM resenas r
             JOIN usuarios u ON r.usuario_id = u.id
             WHERE r.lugar_id = $1 ORDER BY r.fecha DESC`,
            [id]
        );

        res.json({
            ...lugarRes.rows[0],
            resenas: resenasRes.rows
        });
    } catch (err) {
        res.status(500).json({ error: "Error al obtener detalle" });
    }
});

// 6. Reseñas: Crear
app.post('/api/resenas', authenticateToken, async (req, res) => {
    const { lugar_id, comentario } = req.body;
    const userId = req.user.userId;
    try {
        const result = await pool.query(
            'INSERT INTO resenas (lugar_id, usuario_id, comentario) VALUES ($1, $2, $3) RETURNING *',
            [lugar_id, userId, comentario]
        );
        res.status(201).json({ message: "Reseña guardada", resena: result.rows[0] });
    } catch (err) {
        res.status(500).json({ error: "Error al guardar reseña" });
    }
});

// Ruta raíz
app.get('/', (req, res) => {
    res.json({ mensaje: "API de DescubreMiCiudad conectada a Postgres", status: "Online" });
});

app.listen(PORT, () => {
    console.log(`🚀 Servidor corriendo en el puerto ${PORT}`);
});
