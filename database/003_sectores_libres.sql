-- Actualización 1.3: aplicar una vez a un esquema 1.2 existente, después del respaldo.
-- Amplía el texto sin borrar sectores, reportes ni avistamientos.
ALTER TABLE sector MODIFY COLUMN nombre VARCHAR(250) NOT NULL;
