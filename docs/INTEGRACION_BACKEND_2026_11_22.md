# Integración del backend — 22 de noviembre de 2026

## Referencias revisadas

- `BioJaverianaPUJ/backend/main`: `bdac55558f429ff965d8681f0e6b24bc0ef3829b`.
- Comparación desde `8dba2e0`, controladores, DTO y cambios de almacenamiento.
- `feature/achievements`: `9b60c20dbb44b4e8dc2d4434960e5c47ebf2caba`, todavía no integrada en main.
- `docs/swagger`: documentación y anotaciones de la API; `features/test`: pruebas del backend. No son nuevos servicios desplegados.
- El repositorio del backend se consultó sin modificarlo. No se publicaron cambios de frontend en GitHub en esta revisión.

## Cambios disponibles en main

Se implementó la firma real de fotografías de publicaciones y se corrigió la generación de URLs públicas de S3. La firma debe conservarse completa: sustituir el host o volver a codificar la URL invalida la autorización. Los contratos de usuarios, especies, ejemplares, observaciones, posts, comentarios, reportes, sanciones y POI no cambiaron en este intervalo.

El móvil valida la respuesta de presign, carga por PUT con el Content-Type indicado y solo crea la publicación después de una carga correcta. No envía el token de la aplicación al almacenamiento ni sigue redirecciones. Las pruebas verifican firmas con parámetros codificados, errores de almacenamiento y metadatos inválidos. El administrador sigue consumiendo las URLs públicas de imágenes que entrega el backend.

## Corrección de captura y ubicación

Antes se rechazaba la primera lectura con precisión mayor de 5 m, descartando la foto. Ahora se conserva la captura en memoria, se esperan lecturas nuevas durante un máximo de 40 segundos y se muestra la precisión obtenida. Se ignoran coordenadas inválidas y lecturas de más de 15 segundos o del futuro. La suscripción GPS se cierra al obtener una lectura válida o agotar el plazo.

Si falla, se puede reintentar la ubicación sin repetir la foto, siempre permaneciendo en el mismo lugar. Una captura de más de dos minutos exige una nueva fotografía al reintentar. Se mantiene el límite de 5 m: el frontend no inventa coordenadas ni reduce la exigencia del requisito. El dispositivo debe tener ubicación precisa activada. La mejora no garantiza cobertura GPS dentro de edificios. El envío continúa validando el perímetro de referencia existente.

## Integración preparada para feature/achievements

### Móvil

- `GET /gamification/me`: experiencia y nivel del servidor; progreso calculado únicamente con sus umbrales.
- `GET /achievements/me`: logros personales. El estado completed es autoritativo; target nulo no significa logro completado.
- `GET /gamification/me/xp-history?page=&size=20`: historial paginado de XP, motivo, total acumulado y nivel resultante.
- Perfil ajeno: no se muestra la experiencia del usuario autenticado como si perteneciera al perfil consultado.
- HTTP 404/501 muestra función no disponible. Los errores de autenticación o de servidor no se convierten en experiencia cero.
- Las misiones por periodo y las curiosidades permanecen pendientes: esta rama no publica esos contratos.

### Administrador web

Se añadió una sección de logros conectados al servidor, separada de los borradores locales. Permite listar, crear, editar nombre/descripción/recompensa/estado y eliminar con confirmación. Las reglas de creación admiten cantidades de publicaciones, observaciones, comentarios y reacciones recibidas, mediante los eventos y predicados que define la rama.

Las llamadas pasan por la sesión administrativa del servidor web. No se expone el token al navegador, se validan los campos y UUID y se conserva la comprobación de origen. Editar un logro no sobrescribe su regla. Si el servicio aún no existe, se desactiva la creación y se conservan los borradores. Crear un logro no concede XP desde el frontend.

## Pendientes concretos del backend

1. Integrar y desplegar feature/achievements antes de probar gamificación con datos reales. La existencia de una rama no confirma su despliegue.
2. Conectar los eventos a las acciones reales: la búsqueda de publishEvent/dispatch en la rama solo encontró EventDispatcher; no llamadas desde creación de posts, observaciones, comentarios o visitas.
3. Verificar autorización de logros: los controladores usan @PreAuthorize(hasRole('ADMIN')), pero no se encontró EnableMethodSecurity ni conversión de roles JWT a authorities en la rama. Definir también el acceso SUPERADMIN y comprobar rechazos de USER directamente contra la API. El proxy web sí exige rol administrativo, pero no reemplaza la protección del backend.
4. Publicar misiones por periodo, curiosidades y experiencia de perfiles ajenos si se mantienen en los requisitos. No se inventaron rutas para ellos.
5. Permanecen los pendientes anteriores de perímetro institucional y diferencias de permisos/privacidad; este cambio de S3 no los resuelve. Revisar también descripción obligatoria en PostCreateRequest frente al formulario/requisito y consulta de POI inactivos.

## Comprobación del despliegue

El 22 de noviembre las consultas sin sesión a /api/v1/users, /api/v1/posts y /api/v1/pois devolvieron 401, frente al 502 observado el día 20. Esto confirma que el servicio responde y pide autenticación, no que todas las operaciones funcionen. No se crearon usuarios, publicaciones, visitas ni observaciones ficticias en producción.

## Validación

- Flutter: análisis sin incidencias; 46 pruebas de contratos, interfaz y GPS aprobadas (45 en la ejecución completa y la prueba adicional de historial, también aprobada en la ejecución de su archivo). La prueba de capturas opcional se omite por configuración.
- Administrador: compilación de producción correcta, 36 pruebas unitarias/de servidor y 9 recorridos de navegador aprobados.
- Los contratos de gamificación y los recorridos de navegador se probaron con respuestas simuladas del contrato revisado. Falta validación autenticada del despliegue y prueba GPS/cámara en un teléfono dentro del campus.

## APK de pruebas

Versión 1.0.7, código 20261122. Compilación optimizada con paquete com.biojaveriana.client.preview y firma local de pruebas, porque no está disponible la clave oficial de producción. Se instala por separado de com.biojaveriana.client y requiere iniciar sesión de nuevo. No es el artefacto para publicar en Play Store. El script generar-apk-pruebas.bat permite regenerarlo con la configuración local de mapas sin incluir ese archivo en GitHub.

APK generado y firma verificada: Android 7.0 o posterior, ARM de 32/64 bits y x86_64, 123605926 bytes. SHA-256: `E58624EF623C73BB3AE0C9B0E80BC69D16A2F374A4102DAB6685A75F418BBAB0`.
