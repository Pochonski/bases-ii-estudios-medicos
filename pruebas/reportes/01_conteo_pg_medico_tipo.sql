-- P09 (contraste). Conteo médico x tipo calculado en PostgreSQL, fuente clínica.
-- Formato médico|tipo|n para compararlo con 02_conteo_mongo_medico_tipo.js.
\pset tuples_only on
\pset format unaligned
SELECT r.id_medico_firmante || '|' || e.id_tipo || '|' || count(*)
FROM clinico.resultados_estudio AS r
JOIN clinico.estudios AS e ON e.id_estudio = r.id_estudio
GROUP BY r.id_medico_firmante, e.id_tipo
ORDER BY r.id_medico_firmante, e.id_tipo;
