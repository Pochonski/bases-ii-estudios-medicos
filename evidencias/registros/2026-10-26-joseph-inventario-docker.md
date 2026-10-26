# Inventario Docker de la validación Windows — 26/10/2026

Responsable: Joseph. Fuente: `docker-before.json` y `docker-after.json` originales,
conservados sin cambios bajo `.tmp/validacion-main-2840743/.tmp/` en el equipo de
prueba. **Los JSON completos no se publican:** contienen identificadores y nombres
de recursos Docker ajenos a la demostración. Este archivo registra solo la
comparación comprobada.

| Recurso | Antes | Después | Diferencia de identificadores |
|---|---:|---:|---:|
| Contenedores | 7 | 7 | 0 |
| Volúmenes | 17 | 17 | 0 |
| Redes | 6 | 6 | 0 |

Se analizaron los tres arreglos JSON completos y se compararon sus identificadores
con `Compare-Object`. Los dos archivos tienen 1361 bytes y el mismo SHA-256:
`3F5402E28FCC429043743285369B612F3B1C94DC7795AF9B62FA12C3B923CC9B`.
La captura anterior se guardó a las 07:54:12 y la posterior a las 07:59:57
(UTC−06:00), alrededor de la ejecución iniciada a las 07:54:28. Los JSON no
incluyen un identificador de ejecución propio; la secuencia y las horas son la
base de su asociación con el [registro íntegro](2026-10-26-joseph-validacion-integrada-windows.txt).

El proyecto efímero de ese registro fue `joyce-p18-5f7d311360ec`. El log
termina en `PASS limpieza`. Una comprobación Docker posterior encontró **0**
contenedores, **0** volúmenes, **0** redes y **0** etiquetas de imagen con ese
nombre. El inventario demuestra que los recursos preexistentes conservaron sus
identificadores; no es una comparación del contenido interno de cada volumen.
