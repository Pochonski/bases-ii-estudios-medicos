\set ON_ERROR_STOP on
-- LIST sobre la región de REGISTRO del paciente; sin partición DEFAULT.
-- La ausencia de DEFAULT hace fallar códigos no acordados.
BEGIN;
CREATE TABLE clinico.pacientes_sj PARTITION OF clinico.pacientes FOR VALUES IN ('SJ');
CREATE TABLE clinico.pacientes_al PARTITION OF clinico.pacientes FOR VALUES IN ('AL');
CREATE TABLE clinico.pacientes_ca PARTITION OF clinico.pacientes FOR VALUES IN ('CA');
COMMIT;
