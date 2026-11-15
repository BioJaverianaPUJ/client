# Frontend móvil: implementación del SRS

Revisión del 3 de noviembre de 2026. Fuente: SRS versión 0.3, 59 páginas.
Backend consultado en modo de lectura: BioJaverianaPUJ/backend, commit
`8e9c221488b5182ff6daec327226f68761a7ad19`.

## Funciones conectadas a contratos existentes

La URL base permanece configurable con `API_BASE_URL` y por defecto apunta a
`https://biojaveriana.downloadablefox.dev/api/v1`.

| Operación | Contrato utilizado |
|---|---|
| Registro, login y renovación | POST /auth/register, /auth/login, /auth/refresh-token |
| Perfil propio | GET /users/me |
| Perfil de un autor | GET /users/{id}; no se muestra su correo ni su género |
| Editar perfil | PATCH /users/me: firstName, lastName, username, gender |
| Foto y banner | PATCH /users/me/media?type=profile-picture o banner; multipart con parte file |
| Eliminar foto/banner | DELETE /users/me/media?type=profile-picture o banner |
| Catálogo | GET /species?page=…&size=100 y GET /species/{id} |
| Especímenes del mapa | GET /specimens?page=…&size=100 |

El cliente interpreta `content` y `pagination.totalPages`. Permite cargar más
resultados. La búsqueda del catálogo se aplica a las páginas ya cargadas: el
backend revisado no ofrece parámetros de búsqueda. No se cargan todos los
registros ilimitadamente ni se presenta la búsqueda local como global.

La autorización se envía como Bearer. Los errores se presentan en español.
`USER_DEACTIVATED` cierra la sesión y muestra un aviso de suspensión.
La regla de catorce días para cambiar usuario se aplica en el servidor y su error
se traduce con un mensaje específico.

## Pantallas y flujos preparados

- Cinco secciones: Inicio, Mapa, Cámara, Gamificación y Perfil.
- Inicio: feed paginado, refresco, tarjeta de autor, fotos deslizables, acceso al
  perfil, comentarios, me gusta, edición, eliminación y denuncia.
- Editor: título obligatorio, texto opcional, hasta diez imágenes de cámara o
  galería, asociación de observación no fallida, confirmación al descartar y
  conservación del formulario si falla el envío. No persiste borradores al salir.
- Comentarios: respuestas a un nivel, edición/eliminación propias, denuncia con
  motivos suministrados por el servicio.
- Cámara: cámara nativa, permiso/lectura de ubicación, precisión máxima de 5 m,
  una imagen, sin opción de galería. La posición se obtiene inmediatamente al
  regresar de la cámara nativa. No existe seguimiento en segundo plano.
- Observaciones: lista personal y filtros, detalle con foto/especie/confianza/
  fecha/coordenadas/estado, publicar, solicitar revisión sin cambiar estado,
  reenviar fallo respetando retryAt y eliminar con confirmación.
- Mapa: OpenStreetMap con atribución y posición, especímenes oficiales con ficha,
  interfaces para polígono oficial y capas de animales propios, zonas verdes y
  zonas de interés. Las capas sin servicio no simulan datos oficiales.
- Gamificación: curiosidad del día, XP/nivel del servidor, misiones por periodo,
  progreso y logros pendientes/completados, acceso a zonas desde actividades.
- Perfil: consulta y edición real, imágenes, acceso a observaciones/catálogo,
  actividad pública preparada, formularios de contraseña y eliminación.

Los datos ficticios solo se usan dentro de pruebas automatizadas. La aplicación
normal no publica contenido falso, no asigna puntos ni muestra estadísticas
inventadas. Los archivos históricos de MockData no alimentan estas pantallas.

## Servicios pendientes y cómo conectarlos

`CommunityRepository` define los modelos y operaciones usados por las pantallas.
Su implementación predeterminada indica que la función no está disponible.
No contiene rutas hipotéticas ni escritura local que aparente una publicación.
Se inyecta en `SessionController`. Al publicar contratos de servidor, añadir una
implementación y conectarla en la factoría de sesión; los tests ya usan una
implementación alternativa para validar los flujos.

Faltan contratos confirmados para feed, publicaciones, comentarios, me gusta,
denuncias/motivos, observaciones y su reconocimiento, polígono, zonas, visitas,
misiones, logros y curiosidades. La subida de imágenes de publicaciones y
observaciones necesita su propio contrato; no se reutiliza la ruta de perfil.

`AccountRepository` separa cambio de contraseña y eliminación de cuenta. Ambos
permanecen deshabilitados en la aplicación normal. El DELETE /users/{id} existente
es administrativo: no se utiliza para eliminar la cuenta propia.

Antes de activar esos adaptadores se debe acordar:

1. Paginación estable, orden cronológico, identificadores e idempotencia de envíos.
2. Fotografías admitidas, límites y mecanismo de subida/confirmación/limpieza.
3. Solicitud de reconocimiento asíncrona: identificador, consulta o eventos,
   estados transitorios, recuperación tras cerrar la app y reintentos. El adaptador
   de submit debe resolver con el resultado persistido; la infraestructura de
   procesamiento y recuperación no existe todavía en este backend.
4. Confianza normalizada entre 0 y 1; verificación decidida por el servidor.
5. Próximo envío permitido por usuario (cinco minutos, incluidos fallos y reenvíos).
6. Visibilidad de datos personales: hasta aclararlo no se exponen observaciones
   personales de otros usuarios. Solo su actividad pública.
7. Periodos de misiones, zona horaria, progreso/XP autoritativos y visitas
   idempotentes. El tracker consulta ubicación solo en primer plano y con permiso
   concedido, cada 30 segundos; el servidor decide cuándo una visita cuenta.
8. Sesión de dos semanas con renovación al abrir: el cliente conserva la sesión
   real del backend y no extiende localmente un token vencido.

No se ha implementado el panel administrativo web: es un cliente separado del
móvil. Tampoco se han modificado ni publicado cambios en el backend o GitHub.

## Política de tratamiento de datos

Por indicación del usuario, se muestra la opción con el aviso de documento
pendiente y el aviso de mayores de 18 años. El registro de pruebas sigue usando
el contrato vigente. No se solicita ni almacena una aceptación ficticia de una
política inexistente. RF-03 queda pendiente de texto aprobado y de soporte del
backend para guardar versión/fecha de aceptación. Antes de un lanzamiento público
debe completarse este flujo.

## Verificación

- Pruebas de autenticación, suspensión, contrato de perfil/multipart, catálogo,
  reglas de publicación, pertenencia al polígono, formulario ante error y estados
  no disponibles.
- Pruebas de Inicio, Gamificación, login y registro con texto al 200%; Inicio se
  prueba con ancho 360 dp.
- Capturas locales de Inicio, editor y Gamificación con datos exclusivos de prueba
  mediante `flutter test --dart-define=CAPTURE_REVIEW=true`.
- Compilación Android de depuración. No certifica uso real de cámara/GPS ni
  funcionamiento de todo el despliegue: falta la prueba en teléfono con cuenta.
- No se creó una cuenta ni se modificaron datos reales para ejecutar las pruebas.
- iOS no se ha compilado: requiere un entorno macOS y validación en dispositivo.

## Probar en Android

Desde la raíz del proyecto, ejecutar `probar-biojaveriana.bat` con el teléfono
conectado, depuración USB habilitada y autorización de conexión aceptada.
Si aparecen varios dispositivos, elegir Android. El script usa Flutter y cachés
en D: y mantiene la terminal abierta. `r` recarga cambios; `R` reinicia la app;
`q` termina la ejecución.

También puede copiarse `build/app/outputs/flutter-apk/app-debug.apk` al teléfono
e instalarse. Es un APK de pruebas, no una publicación en la tienda.

Recorrido recomendado: registro/login, Inicio y editor, mapa y ficha oficial,
ubicación y cámara, perfil y edición, cambio/eliminación de foto y banner,
catálogo, cierre/reapertura de sesión. Publicar, reconocimiento, actividad y
gamificación muestran su disponibilidad pendiente hasta implementar el servidor.
