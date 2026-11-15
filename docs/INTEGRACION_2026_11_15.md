# Integración del 15 de noviembre de 2026

Referencia: SRS v0.3 de 78 páginas y backend main, commit 521722b. Este documento sustituye las conclusiones de integración anteriores; no certifica que todos los requisitos estén completos ni que se hayan probado escrituras en producción.

## Aplicación móvil

- Publicaciones: consulta paginada, detalle, creación, edición de texto y asociación a observación, eliminación y votos positivos/negativos.
- Comentarios y respuestas de un nivel: consulta, creación, edición, eliminación y seis reacciones.
- Denuncias: envío con motivo y consulta del historial propio.
- Perfil público: muestra el nombre de usuario y evita presentar nombres, correo y género que devuelve el servidor.
- Observaciones: usa el límite temporal del servidor; distingue procesamiento, fallos y verificación conforme a similitud mínima 0,25 y, para plantas, asociación a un ejemplar. No confunde certeza con similitud.
- Mapa: carga puntos de interés públicos activos; conserva el perímetro de referencia y limita los detalles de ejemplares a observaciones verificadas del usuario.
- Fotografías de referencia de especies mediante GBIF, con autor, licencia y enlaces de procedencia; pueden no existir imágenes para una especie.
- Renovación de sesión al restaurar o reanudar la aplicación.

## Administración web

- Publicaciones y comentarios: consulta, ocultar, bloquear, revertir y eliminar con confirmación.
- Denuncias: consulta, contenido reportado y cambio confirmado de estado.
- Usuarios: roles, suspensiones temporales/permanentes, historial, cancelación y eliminación de imágenes de perfil. Protección del administrador inicial y de acciones destructivas sobre la propia cuenta.
- Puntos de interés: consulta y formularios conectados para crear, modificar y eliminar; geometría puntual con radio o polígono, visibilidad y activación. La validación geográfica local usa un perímetro de referencia, no una fuente oficial del backend.
- Mantiene catálogo y consulta de observaciones/revisiones. Los borradores de gamificación, zonas especializadas y perímetro siguen siendo locales y están identificados como tales.

## Bloqueos y diferencias del backend

1. POST /posts/presign devuelve una URL vacía. Impide subir fotos de publicaciones. La aplicación conserva el formulario y muestra un error, sin fingir una publicación exitosa. El DTO de edición tampoco permite modificar imágenes.
2. El servidor exige descripción no vacía para publicaciones, aunque RF25 la define opcional. Título y texto tienen límite de 200 caracteres en la aplicación.
3. PoiService compara por referencia los Double del primer y último vértice. Puede rechazar polígonos correctamente cerrados. Corregir esa comparación en el backend antes de validar el flujo real de polígonos.
4. No hay API de experiencia, misiones, logros ni curiosidades. No se inventan puntos o progreso; los editores administrativos son borradores.
5. Los POI no incluyen clasificación de zona verde/interés, color ni asociaciones con actividades. Tampoco sustituyen una API de perímetro oficial con validación de entidades existentes (RF62).
6. Hay comprobaciones que aceptan ADMIN pero rechazan SUPERADMIN en servicios, aunque el control general admite ambos. Deben unificarse los permisos del servidor.
7. Los perfiles públicos del backend devuelven datos personales: ocultarlos en el móvil no corrige la exposición de la API. Debe corregirse el DTO público.
8. No hay servicios para eliminar/reintentar observaciones ni eliminar denuncias finalizadas. La resolución y las sanciones de denuncias no están coordinadas automáticamente; el administrador cambia explícitamente su estado.
9. El backend no expone el estado de publicación de una observación. No se puede certificar ese indicador ni la restricción de publicación única únicamente desde el cliente.
10. Falta garantizar en servidor el alta/actualización de ejemplares por cercanía de 1 m y las restricciones territoriales. Los formularios afectados conservan el bloqueo preventivo existente.
11. La prevención de denuncias duplicadas y la visibilidad de contenido oculto/bloqueado requieren revisión de extremo a extremo en el backend. No basta con ocultar botones en la interfaz.

## Validación y entrega

- Flutter: análisis sin incidencias y 34 pruebas aprobadas; una prueba de capturas omitida por defecto.
- Admin: 31 pruebas unitarias/de servidor, incluidas las respuestas de error de inicio de sesión. La compilación comprueba TypeScript y genera el sitio.
- Pruebas de navegador con respuestas simuladas: acceso, catálogo, borradores, usuarios, accesibilidad, revisiones, puntos de interés y denuncias.
- Las pruebas automatizadas no crean usuarios, publicaciones ni sanciones en la base desplegada. Hace falta una prueba integrada con cuentas de prueba después de resolver los bloqueos anteriores.
- Configuración local y claves excluidas de publicación. La actualización se publica en los repositorios client y adminWeb; la configuración local permanece excluida.

## Probar

Móvil: instalar BioJaveriana-1.0.5.apk desde build/app/outputs/flutter-apk. Es una compilación de desarrollo para pruebas, no una entrega firmada de tienda.

Administrador: abrir una terminal en BioJaverianaAdminWeb y ejecutar .\iniciar-admin.bat. Abrir http://localhost:5173 y mantener la terminal abierta. Se necesita una cuenta ADMIN o SUPERADMIN real; algunas operaciones SUPERADMIN siguen sujetas al problema del servidor descrito arriba.
