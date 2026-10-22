# Requisitos del enunciado y trazabilidad

**Fuente:** enunciado del curso (5 páginas), «Segundo Proyecto — Sistema de Gestión de Estudios Médicos Distribuido». El documento original no está incluido en este repositorio público; se citan páginas y apartados para que el equipo los contraste con la copia disponible en el curso. No confundir requisitos del profesor con las propuestas del grupo.

## Descripción general (p. 1)

- [CURSO] Sistema de bases de datos distribuidas que soporte futuras aplicaciones web/móvil para gestión de estudios médicos; **no se desarrolla la app web ni móvil**.
- [CURSO] Tres motores: PostgreSQL transaccional, SQL Server integración externa, MongoDB NoSQL analítico.

## Responsabilidad de motores (pp. 1–3)

- [CURSO] PostgreSQL: pacientes, médicos, administrativos, citas, resultados, diagnósticos, órdenes; integridad y reglas de negocio; segmentación horizontal por región/sucursal; acceso FDW a SQL Server y conexión con MongoDB.
- [CURSO] SQL Server: aseguradoras, servicios públicos, sistemas de facturación (simulados), segmentación vertical de atributos, procedimientos almacenados y tablas/vistas federadas.
- [CURSO] MongoDB: documentos desnormalizados de estudios y reportes, agregaciones por médico/tipo y métricas.

## Integración y seguridad (pp. 3–4)

- [CURSO] Documentar canales FDW, consultas cruzadas, roles de clúster internos y roles externos para web/móvil.
- [CURSO] Internos: `usr_fdw_pg_mssql`, `usr_fdw_pg_mongo`, privilegios mínimos.
- [CURSO] Externos: `usr_api_web`, `usr_api_mobile`, permisos diferenciados y autenticación.
- [ATENCIÓN] Texto en p. 2 admite «mongo_fdw o integración intermedia», mientras p. 3 pide «usar mongo_fdw». Resolver con profesor si el método cambia.

## Cinco operaciones de aceptación (p. 4)

| ID | Requisito literal resumido | Evidencia propuesta |
|---|---|---|
| INT-01 | Consulta PostgreSQL de paciente y estado de facturación desde SQL Server | P01 + P02; resultado con filas combinadas |
| INT-02 | Inserción PostgreSQL que, tras confirmarse, actualiza resumen MongoDB | P04 + P05 + P06/P13 |
| INT-03 | Vista PostgreSQL con datos locales y remotos SQL Server para web | P02/P03 + vista `api` |
| INT-04 | Exportación hacia MongoDB para reportes agregados | P05 y cotejo de registros |
| INT-05 | Consulta analítica MongoDB agregada por médico y tipo | P09 |

## Entregables (p. 5)

1. Modelo BD e indicación horizontal/vertical.
2. Scripts de creación/configuración de **los tres motores**.
3. FDW documentados: `postgresql.conf`, `pg_hba.conf`, `CREATE SERVER`, etc.
4. Usuarios, perfiles y privilegios realmente configurados.
5. Consultas de integración y operaciones entre motores.
6. Video demostrativo narrado de **5 a 8 min** con arquitectura, mapa de conexiones, consultas en tres servidores, transacciones/integraciones y capturas de conexión; los tres integrantes deben explicar su participación.
7. Archivos fuente y documentación enviados por Moodle; referencias bibliográficas documentadas.

## Administración (p. 5)

- El enunciado dice que puede desarrollarse en **«grupos de 4 personas»**; nuestro grupo real tiene 3. El texto no aclara expresamente el caso de grupos de 3, por lo que conviene confirmar su aceptación. Prohíbe plagio.
- Retraso: **10% de nota final por cada hora** según el texto del enunciado.
- Recomienda control de versiones. Se elige Git.
- Fecha de inicio: **martes 13/10/2026**; entrega indicada: **28/10/2026, 23:59**, con error entre día y fecha: confirmar Moodle.

## Exclusiones explícitas vs decisiones nuestras

**No requerido:** implementar web/móvil. **No solicitado literalmente:** clúster físico multinodo, alta disponibilidad real, pagos electrónicos, imágenes DICOM, servicios externos conectados de verdad, API HTTP, autenticación de pacientes, pruebas masivas de carga. No añadirlos al camino crítico.
