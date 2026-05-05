local sqlite3 = require('./backend/deps/sqlite3')
local db = sqlite3.open('backend/cibercafe.db')

local schema = [[
CREATE TABLE IF NOT EXISTS usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    telefono TEXT,
    password TEXT NOT NULL,
    fecha_nacimiento TEXT,
    puntos INTEGER NOT NULL DEFAULT 0,
    rol TEXT DEFAULT 'cliente'
);

CREATE TABLE IF NOT EXISTS equipos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre TEXT NOT NULL,
    estado TEXT NOT NULL DEFAULT 'Libre',
    hora_inicio TEXT
);

CREATE TABLE IF NOT EXISTS reservas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    usuario_id INTEGER,
    equipo_id INTEGER,
    fecha TEXT,
    hora TEXT,
    pin TEXT,
    activa INTEGER DEFAULT 1,
    usada INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    FOREIGN KEY (equipo_id) REFERENCES equipos(id)
);

CREATE TABLE IF NOT EXISTS configuracion (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nombre_local TEXT NOT NULL,
    precio_hora REAL NOT NULL
);

INSERT OR IGNORE INTO usuarios (id, nombre, email, password, rol) VALUES 
(1, 'Admin', 'admin@cibervicio.com', '123', 'admin'),
(2, 'Manolo el Prisas', 'manolo@pepe.com', '123', 'cliente');

INSERT OR IGNORE INTO configuracion (id, nombre_local, precio_hora) VALUES (1, 'El Ciber del Vicio', 3.50);

INSERT OR IGNORE INTO equipos (id, nombre, estado) VALUES 
(1, 'PC-Patata-01', 'Libre'), 
(2, 'PC-Tostadora-02', 'Ocupado'), 
(3, 'PC-Gamer-03', 'Reservado'), 
(4, 'PC-NASA-04', 'Libre');
]]

db:exec(schema)
db:close()
print("Base de datos SQLite inicializada!")
