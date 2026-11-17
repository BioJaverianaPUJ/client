# Revisión del backend — 16 de noviembre de 2026

Se comparó main desde 521722b hasta 8dba2e0 (PR #12). Hay cuatro archivos modificados; no se añadieron endpoints ni DTO nuevos.

## Cambios del backend

- Retira dependencias y autoconfiguraciones que impedían el arranque.
- Sustituye consultas específicas de PostGIS por detección en Java: distancia Haversine para puntos con radio y JTS para polígonos.
- Mantiene POST /pois/telemetry, que devuelve solo las visitas recién registradas. Una respuesta vacía puede indicar deduplicación; no significa fallo.

El despliegue respondió HTTP 401 con JSON de autenticación en /api/v1/users y /api/v1/pois durante esta revisión. Ya no se reprodujo el 502 anterior. Esto confirma respuesta del servicio, no una prueba de inicio de sesión ni de escritura autenticada.

## Ajustes del frontend

Móvil: la comprobación de entrada en un POI se delega al servidor. Se elimina la descarga de todas las zonas en cada comprobación y el filtro basado en círculos aproximados del mapa, que podía descartar posiciones válidas cerca del radio. Se mantienen permiso previo, primer plano, sesión iniciada, precisión máxima de cinco metros, intervalo de treinta segundos y restricción al perímetro de referencia del campus. No se asigna experiencia local ni se acumulan ubicaciones para enviarlas posteriormente.

Administrador: permite actualizar la lista de puntos de interés y reintentar tras un fallo. Un error ya no se presenta a la vez como una lista vacía.

## Pendientes que no cambiaron

Siguen pendientes la URL de carga de fotos de publicaciones, servicios de gamificación y experiencia, perímetro institucional y diferencias de permisos y privacidad descritas en INTEGRACION_2026_11_15.md. La corrección de detección de visitas no corrige la comparación por referencia de coordenadas al crear polígonos. El listado de POI sigue devolviendo solo activos: hace falta soporte del backend para consultar y recuperar inactivos desde la interfaz.

La comprobación de visitas reales necesita una sesión y ubicación física autorizada. No se generaron visitas ficticias ni se alteró el backend.

## Validación de esta revisión

Flutter: análisis sin incidencias, 35 pruebas aprobadas y una prueba de capturas omitida por configuración. Administrador: compilación correcta, 31 pruebas unitarias/de servidor y 8 recorridos de navegador aprobados. Las pruebas de contratos y navegador usan respuestas simuladas. No se generó un APK nuevo ni se publicó esta revisión en GitHub.
