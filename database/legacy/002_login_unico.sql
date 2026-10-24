-- Ejecutar una vez sobre una instalación existente; conserva reportes y referencias.
-- El usuario y la contraseña se validan únicamente en la plataforma central.
CREATE TABLE IF NOT EXISTS login (
 usuario_id VARCHAR(128) COLLATE utf8mb4_bin PRIMARY KEY,
 emisor VARCHAR(255) COLLATE utf8mb4_bin NOT NULL,
 nombre_usuario VARCHAR(120),
 nombre_visible VARCHAR(160),
 primer_acceso TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 ultimo_acceso TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_login_usuario FOREIGN KEY(usuario_id) REFERENCES usuario_referencia(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
