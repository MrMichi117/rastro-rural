-- MySQL 8.4 LTS (también compatible con MySQL 8.0.16+).
-- Seleccionar previamente la base de datos; no contiene credenciales ni borra datos.
CREATE TABLE especie (
 id INT PRIMARY KEY AUTO_INCREMENT,
 nombre VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE sector (
 id INT PRIMARY KEY AUTO_INCREMENT,
 nombre VARCHAR(250) NOT NULL UNIQUE,
 descripcion VARCHAR(250)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE reporte (
 id BIGINT PRIMARY KEY AUTO_INCREMENT,
 usuario_id VARCHAR(128) COLLATE utf8mb4_bin NOT NULL,
 usuario_emisor VARCHAR(255) COLLATE utf8mb4_bin NOT NULL,
 usuario_nombre VARCHAR(160),
 especie_id INT NOT NULL,
 especie_otro VARCHAR(80),
 nombre_animal VARCHAR(100),
 identificador_campo VARCHAR(100),
 senas VARCHAR(1000) NOT NULL,
 descripcion VARCHAR(2000) NOT NULL,
 sector_id INT NOT NULL,
 fecha_perdida DATE NOT NULL,
 creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 actualizado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 estado VARCHAR(16) NOT NULL DEFAULT 'BUSCANDO',
 version INT NOT NULL DEFAULT 0,
 foto MEDIUMBLOB,
 foto_tipo VARCHAR(30),
 CONSTRAINT fk_reporte_especie FOREIGN KEY(especie_id) REFERENCES especie(id),
 CONSTRAINT fk_reporte_sector FOREIGN KEY(sector_id) REFERENCES sector(id),
 CONSTRAINT chk_estado CHECK (estado IN ('BUSCANDO','ENCONTRADO','CANCELADO')),
 INDEX idx_tablero (estado,creado_en,id),
 INDEX idx_filtros (estado,especie_id,sector_id),
 INDEX idx_autor (usuario_id,usuario_emisor,creado_en)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE avistamiento (
 id BIGINT PRIMARY KEY AUTO_INCREMENT,
 reporte_id BIGINT NOT NULL,
 usuario_id VARCHAR(128) COLLATE utf8mb4_bin NOT NULL,
 usuario_emisor VARCHAR(255) COLLATE utf8mb4_bin NOT NULL,
 usuario_nombre VARCHAR(160),
 sector_id INT NOT NULL,
 fecha_avistamiento DATETIME NOT NULL,
 observacion VARCHAR(2000) NOT NULL,
 creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY(reporte_id) REFERENCES reporte(id),
 FOREIGN KEY(sector_id) REFERENCES sector(id),
 INDEX idx_avistamientos (reporte_id,fecha_avistamiento)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
CREATE TABLE encuesta (
 id BIGINT PRIMARY KEY AUTO_INCREMENT,
 usuario_id VARCHAR(128) COLLATE utf8mb4_bin NOT NULL,
 usuario_emisor VARCHAR(255) COLLATE utf8mb4_bin NOT NULL,
 usuario_nombre VARCHAR(160),
 subproyecto_id VARCHAR(40) NOT NULL DEFAULT 'rastro-rural',
 version_encuesta INT NOT NULL DEFAULT 1,
 respuesta_1 TINYINT NOT NULL CHECK(respuesta_1 BETWEEN 1 AND 5),
 respuesta_2 TINYINT NOT NULL CHECK(respuesta_2 BETWEEN 1 AND 5),
 respuesta_3 TINYINT NOT NULL CHECK(respuesta_3 BETWEEN 1 AND 5),
 respuesta_4 TINYINT NOT NULL CHECK(respuesta_4 BETWEEN 1 AND 5),
 respuesta_5 TINYINT NOT NULL CHECK(respuesta_5 BETWEEN 1 AND 5),
 creado_en TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
 UNIQUE KEY uq_encuesta(usuario_id,usuario_emisor,subproyecto_id,version_encuesta)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
INSERT INTO especie(nombre) VALUES ('Bovino'),('Canino'),('Equino'),('Felino'),('Porcino'),('Ovino'),('Caprino'),('Ave'),('Otro');
-- Los sectores se describen al crear reportes o avistamientos; no hay lista predefinida.
