# Entrega actual — 15 de noviembre de 2026

Autor: Brayan Fajardo.

Esta entrega reúne el frontend móvil y el administrador web de BioJaveriana, alineados con la revisión de 78 páginas del SRS v0.3 y los contratos del backend revisados en el commit 521722b. La rama main contiene la versión integrada de cada proyecto.

## Aplicación móvil — Flutter y Dart

- Identidad BioJaveriana: nombre, logo, icono, pantalla de inicio y estética verde/lima con superficies de vidrio, fondos ilustrados y navegación móvil.
- Registro, inicio y cierre de sesión, persistencia y renovación de sesión; perfil propio y presentación restringida de datos en perfiles públicos.
- Inicio comunitario con publicaciones paginadas, detalle, creación, edición de texto, asociación a observaciones y eliminación.
- Votos positivos y negativos; comentarios, respuestas de un nivel, edición, eliminación y seis reacciones.
- Envío de denuncias y consulta del historial propio.
- Catálogo de especies y fotografías de referencia con procedencia y licencia.
- Captura y consulta de observaciones, estados de procesamiento y fallos, verificación por similitud y asociación a ejemplares según corresponda.
- Mapa con CARTO, perímetro de referencia del campus, ejemplares, observaciones y puntos de interés públicos activos.
- Pantallas de gamificación preparadas; la experiencia y los logros no se presentan como datos reales mientras no exista soporte del backend.

## Administrador web — React, TypeScript, Vite y Express

- Aplicación independiente con estética de BioJaveriana, navegación adaptable y acceso administrativo.
- Servidor intermediario que mantiene los tokens fuera del navegador; sesiones con cookie HttpOnly y validación de origen y permisos.
- Catálogo de especies y consulta/edición de ejemplares, con restricciones donde faltan garantías del backend.
- Consulta de observaciones y solicitudes de revisión.
- Gestión de usuarios y roles, suspensiones temporales o permanentes, historial y cancelación de suspensiones; protección de la cuenta administradora inicial.
- Moderación de publicaciones y comentarios: consulta, ocultar, bloquear, revertir y eliminar.
- Consulta de denuncias, contenido reportado y cambios de estado confirmados.
- Gestión de puntos de interés con geometría, radio, visibilidad y activación.
- Borradores locales para perímetro, zonas especializadas, misiones, logros y curiosidades; no se confunden con información publicada.
- Mensajes diferenciados de credenciales incorrectas, sesiones vencidas e indisponibilidad del backend, incluido HTTP 502.

## Validación

Flutter pasó el análisis, 34 pruebas y la comprobación de capturas. El administrador pasó 31 pruebas unitarias/de servidor, 7 recorridos de navegador y la compilación TypeScript/Vite. Los recorridos automatizados emplean datos simulados; no certifican todas las operaciones contra producción. El APK de prueba generado es BioJaveriana 1.0.5, compilación 6; no se incluye el binario en Git.

## Pendientes reales

La subida de fotos de publicaciones está bloqueada por una URL de carga vacía del backend. Persisten diferencias en validación de polígonos y permisos SUPERADMIN, exposición de datos en perfiles públicos y ausencia de servicios para experiencia, misiones, logros y perímetro institucional. Tampoco están disponibles todas las operaciones de eliminación/reintento ni las garantías territoriales exigidas por el SRS. El último diagnóstico de acceso detectó HTTP 502 en el servidor desplegado; esta entrega no corrige el despliegue del backend.

El detalle de contratos y limitaciones está en [el informe de integración](INTEGRACION_2026_11_15.md). Las notas anteriores se conservan como historial y deben interpretarse según esta entrega.

## Configuración y ejecución

No se publican claves, archivos .env, config.local.json, dependencias instaladas ni compilaciones. Utilizar los archivos de configuración de ejemplo y las instrucciones del README. Las claves locales deben configurarse por separado.
