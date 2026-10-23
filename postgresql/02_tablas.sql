\set ON_ERROR_STOP on
-- Modelo V1 de docs/03_MODELO_DATOS.md: once tablas clínicas y un outbox local.
-- No instala FDW, worker, vistas API ni objetos SQL Server/MongoDB.
BEGIN;

CREATE TABLE clinico.regiones (
    codigo_region char(2) PRIMARY KEY,
    nombre varchar(60) NOT NULL UNIQUE,
    CONSTRAINT regiones_codigo_chk CHECK (codigo_region IN ('SJ', 'AL', 'CA')),
    CONSTRAINT regiones_nombre_chk CHECK (btrim(nombre) <> '')
);

CREATE TABLE clinico.sucursales (
    id_sucursal integer PRIMARY KEY CHECK (id_sucursal > 0),
    codigo_region char(2) NOT NULL REFERENCES clinico.regiones (codigo_region),
    nombre varchar(100) NOT NULL CHECK (btrim(nombre) <> ''),
    direccion varchar(200),
    activa boolean NOT NULL DEFAULT true
);

CREATE TABLE clinico.pacientes (
    id_paciente bigint NOT NULL CHECK (id_paciente > 0),
    codigo_region char(2) NOT NULL REFERENCES clinico.regiones (codigo_region),
    nombre varchar(80) NOT NULL CHECK (btrim(nombre) <> ''),
    apellidos varchar(120) NOT NULL CHECK (btrim(apellidos) <> ''),
    fecha_nacimiento date NOT NULL,
    telefono varchar(20),
    correo varchar(120),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pacientes_pk PRIMARY KEY (id_paciente, codigo_region)
) PARTITION BY LIST (codigo_region);
COMMENT ON COLUMN clinico.pacientes.codigo_region IS
    'Región de registro del paciente; la región de atención proviene de citas.id_sucursal.';

CREATE TABLE clinico.medicos (
    id_medico bigint PRIMARY KEY CHECK (id_medico > 0),
    nombre varchar(80) NOT NULL CHECK (btrim(nombre) <> ''),
    apellidos varchar(120) NOT NULL CHECK (btrim(apellidos) <> ''),
    especialidad varchar(100) NOT NULL CHECK (btrim(especialidad) <> ''),
    activo boolean NOT NULL DEFAULT true
);

CREATE TABLE clinico.usuarios_administrativos (
    id_usuario bigint PRIMARY KEY CHECK (id_usuario > 0),
    nombre varchar(120) NOT NULL CHECK (btrim(nombre) <> ''),
    correo varchar(120) NOT NULL UNIQUE CHECK (btrim(correo) <> ''),
    activo boolean NOT NULL DEFAULT true
);

CREATE TABLE clinico.citas (
    id_cita bigint PRIMARY KEY CHECK (id_cita > 0),
    id_paciente bigint NOT NULL,
    codigo_region char(2) NOT NULL,
    id_medico bigint NOT NULL REFERENCES clinico.medicos (id_medico),
    id_sucursal integer NOT NULL REFERENCES clinico.sucursales (id_sucursal),
    fecha_hora timestamptz NOT NULL,
    estado varchar(20) NOT NULL,
    CONSTRAINT citas_paciente_fk FOREIGN KEY (id_paciente, codigo_region)
        REFERENCES clinico.pacientes (id_paciente, codigo_region),
    CONSTRAINT citas_estado_chk CHECK (estado IN ('PROGRAMADA', 'COMPLETADA', 'CANCELADA'))
);
COMMENT ON COLUMN clinico.citas.codigo_region IS
    'Región de registro del paciente para la FK compuesta; NO es la región de atención.';

CREATE TABLE clinico.ordenes_medicas (
    id_orden bigint PRIMARY KEY CHECK (id_orden > 0),
    id_cita bigint NOT NULL REFERENCES clinico.citas (id_cita),
    fecha_emision timestamptz NOT NULL,
    indicaciones text,
    estado varchar(20) NOT NULL CHECK (btrim(estado) <> '')
);

CREATE TABLE clinico.tipos_estudio (
    id_tipo integer PRIMARY KEY CHECK (id_tipo > 0),
    nombre varchar(100) NOT NULL UNIQUE CHECK (btrim(nombre) <> ''),
    categoria varchar(60),
    descripcion text
);

CREATE TABLE clinico.estudios (
    id_estudio bigint PRIMARY KEY CHECK (id_estudio > 0),
    id_orden bigint NOT NULL REFERENCES clinico.ordenes_medicas (id_orden),
    id_tipo integer NOT NULL REFERENCES clinico.tipos_estudio (id_tipo),
    estado varchar(20) NOT NULL,
    fecha_realizacion timestamptz,
    CONSTRAINT estudios_estado_chk CHECK
        (estado IN ('SOLICITADO', 'EN_PROCESO', 'FINALIZADO', 'CANCELADO'))
);

CREATE TABLE clinico.resultados_estudio (
    id_resultado bigint PRIMARY KEY CHECK (id_resultado > 0),
    id_estudio bigint NOT NULL UNIQUE REFERENCES clinico.estudios (id_estudio),
    id_medico_firmante bigint NOT NULL REFERENCES clinico.medicos (id_medico),
    resumen text NOT NULL CHECK (btrim(resumen) <> ''),
    fecha_resultado timestamptz NOT NULL,
    revision integer NOT NULL DEFAULT 1 CHECK (revision > 0)
);

CREATE TABLE clinico.diagnosticos (
    id_diagnostico bigint PRIMARY KEY CHECK (id_diagnostico > 0),
    id_resultado bigint NOT NULL REFERENCES clinico.resultados_estudio (id_resultado),
    descripcion text NOT NULL CHECK (btrim(descripcion) <> ''),
    codigo_diagnostico varchar(30)
);

CREATE TABLE integracion.eventos_integracion (
    id_evento uuid PRIMARY KEY,
    id_estudio bigint NOT NULL REFERENCES clinico.estudios (id_estudio),
    revision integer NOT NULL CHECK (revision > 0),
    tipo_evento varchar(40) NOT NULL CHECK (btrim(tipo_evento) <> ''),
    estado varchar(20) NOT NULL DEFAULT 'PENDIENTE',
    intentos integer NOT NULL DEFAULT 0 CHECK (intentos >= 0),
    fecha_creacion timestamptz NOT NULL DEFAULT now(),
    fecha_procesamiento timestamptz,
    CONSTRAINT eventos_estado_chk CHECK (estado IN ('PENDIENTE', 'PROCESADO', 'ERROR'))
);
COMMENT ON TABLE integracion.eventos_integracion IS
    'Estructura local de outbox; no implica que exista un worker ni exportación MongoDB.';

-- Los PK/UNIQUE cubren sus columnas, pero PostgreSQL no indexa automáticamente las FK.
CREATE INDEX sucursales_region_idx ON clinico.sucursales (codigo_region);
CREATE INDEX citas_paciente_idx ON clinico.citas (id_paciente, codigo_region);
CREATE INDEX citas_medico_idx ON clinico.citas (id_medico);
CREATE INDEX citas_sucursal_idx ON clinico.citas (id_sucursal);
CREATE INDEX ordenes_cita_idx ON clinico.ordenes_medicas (id_cita);
CREATE INDEX estudios_orden_idx ON clinico.estudios (id_orden);
CREATE INDEX estudios_tipo_idx ON clinico.estudios (id_tipo);
CREATE INDEX resultados_firmante_idx ON clinico.resultados_estudio (id_medico_firmante);
CREATE INDEX diagnosticos_resultado_idx ON clinico.diagnosticos (id_resultado);
CREATE INDEX eventos_pendientes_idx ON integracion.eventos_integracion (estado, fecha_creacion);
CREATE INDEX eventos_estudio_revision_idx ON integracion.eventos_integracion (id_estudio, revision);
COMMIT;
