\set ON_ERROR_STOP on
-- Precondiciones: Joyce entregó la vista/servicio; integracion/01 aplicado.
BEGIN;
SET LOCAL ROLE usr_fdw_pg_mssql;
SELECT * FROM externo.ft_estado_facturacion ORDER BY id_paciente, codigo_region;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM externo.ft_estado_facturacion
             GROUP BY id_paciente, codigo_region HAVING count(*) > 1) THEN
    RAISE EXCEPTION 'Contrato roto: mas de una fila por paciente-region';
  END IF;
END $$;
ROLLBACK;
-- Una salida vacía comprueba conectividad, pero no el caso funcional con pacientes.