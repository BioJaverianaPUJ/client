# Revisión del backend y APK de pruebas — 20 de noviembre de 2026

## Alcance

Comparación de `BioJaverianaPUJ/backend` entre `8dba2e0` y `d6dc31b`, revisión del inventario de controladores y de todos los archivos modificados en ese intervalo. No se modificó el backend.

## Novedades

- `POST /posts/presign` devuelve una URL de carga real mediante ObjectService.
- Las firmas PUT se generan usando el endpoint público de S3; sustituir el host después de firmar invalidaba la firma.
- Las URLs de lectura de imágenes usan el endpoint público.
- No se incorporaron endpoints ni DTO nuevos; permanecen los contratos de autenticación, usuarios, especies, ejemplares, observaciones, publicaciones, comentarios, reportes, sanciones y POI.

## Aplicación móvil

- Se conserva la URL firmada exacta y se sube la imagen antes de publicar sus claves. El token de sesión nunca se adjunta a la carga de almacenamiento y no se siguen redirecciones.
- Validación de respuestas de carga incompletas y direcciones inválidas; mensaje recuperable cuando no se puede preparar una fotografía.
- Pruebas de carga correcta, fallo de almacenamiento sin publicación y rechazo de metadatos inválidos.
- Sincronización de los cambios Android/iOS y compilación de `client/main` hasta `3b2432c`, preservando el código móvil local.
- Opción explícita Gradle `bioTestBuild=true`: APK optimizado con firma local de pruebas y paquete `com.biojaveriana.client.preview`. No reemplaza la aplicación oficial ni usa su clave de firma. Producción sigue requiriendo `android/app/key.properties`.

## Estado del despliegue

Durante la revisión, GET /api/v1/users, /api/v1/posts y /api/v1/pois respondieron HTTP 502. No fue posible confirmar cargas autenticadas contra producción. Las pruebas automatizadas de contratos usan respuestas simuladas, no prueban la disponibilidad del despliegue.

## Pendientes del backend

La corrección de imágenes no incorpora experiencia/gamificación ni perímetro institucional. PostCreateRequest aún exige descripción aunque el SRS la contempla como opcional. Continúan las diferencias de permisos y privacidad de las revisiones anteriores; no se asignan puntos localmente ni se inventan servicios.
