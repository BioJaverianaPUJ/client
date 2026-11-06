# Rediseño visual — BioJaveriana 1.0.2

Fecha: 4 de noviembre de 2026.

## Criterio visual

Los mockups originales son la referencia: verde profundo, acentos lima, ilustraciones botánicas existentes, superficies transparentes y superficies esmeriladas. No se generaron logos ni ilustraciones nuevas.

- `BioScene`: fondo con iluminación radial y composición de las ilustraciones originales; los adornos no reciben gestos.
- `BioGlassCard`: tarjeta con desenfoque, reflejos y bordes iluminados. El material transparente deja ver la ilustración; el esmerilado protege la lectura de contenido denso.
- `BioPageHeading` y `BioGlassAction`: jerarquía de títulos, acentos, descripciones y acciones consistente.
- Navegación de cinco secciones con vidrio esmerilado e icono seleccionado en relieve.
- Campos, botones secundarios, filtros, diálogos y hojas de detalle armonizados con la paleta.

## Pantallas

- Inicio: identidad de marca, introducción editorial, acceso al editor y al catálogo, tarjetas esmeriladas para publicaciones.
- Catálogo: fondo de árbol, encabezado y tarjetas transparentes; conserva búsqueda y paginación.
- Mapa: encabezado, fondo de aves y marco esmerilado alrededor de la cartografía real.
- Cámara: marco floral, presentación de identificación y panel de encuadre; conserva captura y validación de ubicación.
- Observaciones: árbol de fondo, encabezado, filtros redondeados y tarjetas.
- Perfil: aves de fondo, panel de identidad, avatar y accesos en vidrio; conserva foto, banner y edición.
- Gamificación: ilustración de aves, encabezado y tarjetas de curiosidades y misiones.
- Publicaciones, comentarios, formularios de cuenta y detalles: fondo, controles y materiales compartidos.
- Acceso y registro: ajustes de brillo, transparencia, logo adaptable y eliminación de bordes duplicados en los campos.
- Recuperación: composición con logo, ilustración de gato y panel transparente; informa que el servicio sigue pendiente.

## Comportamiento conservado

Se mantienen las integraciones existentes. Este cambio no crea endpoints ni simula publicaciones, identificación o puntuaciones. Se conservan las cinco secciones de navegación y los requisitos actuales, aunque algunos mockups antiguos muestran cuatro. La identificación sigue usando exclusivamente la cámara; la galería permanece en publicaciones. La política de datos continúa pendiente de documento aprobado.

## Verificación

Análisis estático y pruebas de autenticación, contratos, navegación y accesibilidad. Capturas a 390 × 844 de diez pantallas en `build/review`; los datos que aparecen en dichas capturas provienen exclusivamente de fixtures de pruebas. No representan contenido del servidor.

El APK de depuración se entrega como `build/app/outputs/flutter-apk/BioJaveriana-1.0.2.apk`. La revisión en un teléfono físico queda a cargo de la prueba de instalación: las capturas automatizadas no miden fluidez del dispositivo ni prueban permisos reales de cámara y GPS.

## Instalar desde PowerShell

Con el teléfono conectado y la depuración USB autorizada:

```powershell
& "D:\dev\android\platform-tools\adb.exe" devices
& "D:\dev\android\platform-tools\adb.exe" install -r "D:\Universidad Javeriana\Proyecto Final\biojaveriana\flutter_app\build\app\outputs\flutter-apk\BioJaveriana-1.0.2.apk"
```

El dispositivo debe aparecer como `device`. No es necesario desinstalar la versión anterior si ambas usan la misma firma y el mismo identificador.
