CREATE TABLE IF NOT EXISTS usuarios (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  email VARCHAR(150) UNIQUE NOT NULL,
  password VARCHAR(255) NOT NULL,
  foto_url TEXT,
  creado_en TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS lugares (
  id SERIAL PRIMARY KEY,
  nombre VARCHAR(100) UNIQUE NOT NULL,
  categoria VARCHAR(50) NOT NULL,
  precio VARCHAR(10) NOT NULL,
  price_level VARCHAR(20) NOT NULL,
  rating DECIMAL(2,1) NOT NULL,
  distancia VARCHAR(20) NOT NULL,
  descripcion TEXT NOT NULL,
  imagen_url TEXT NOT NULL,
  lat DECIMAL(10,7) NOT NULL,
  lng DECIMAL(10,7) NOT NULL,
  imagen TEXT,
  latitud DOUBLE PRECISION,
  longitud DOUBLE PRECISION,
  direccion TEXT,
  como_llegar TEXT
);

CREATE TABLE IF NOT EXISTS resenas (
  id SERIAL PRIMARY KEY,
  lugar_id INTEGER REFERENCES lugares(id) ON DELETE CASCADE,
  usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
  comentario TEXT NOT NULL,
  rating INTEGER DEFAULT 5,
  fecha TIMESTAMP DEFAULT NOW(),
  UNIQUE(usuario_id, lugar_id)
);

CREATE TABLE IF NOT EXISTS favoritos (
  id SERIAL PRIMARY KEY,
  usuario_id INTEGER REFERENCES usuarios(id) ON DELETE CASCADE,
  lugar_id INTEGER REFERENCES lugares(id) ON DELETE CASCADE,
  creado_en TIMESTAMP DEFAULT NOW(),
  UNIQUE(usuario_id, lugar_id)
);
