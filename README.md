# BioJaveriana — aplicación móvil

Aplicación Flutter/Dart para explorar la biodiversidad del campus, consultar especies y especímenes, registrar observaciones y gestionar el perfil.

## Requisitos

Flutter con Dart 3.12.2 o compatible con `pubspec.yaml`, Android SDK y un dispositivo o emulador. Para iOS se requiere macOS y Xcode.

## Ejecutar

Desde la raíz del repositorio:

```sh
flutter pub get
flutter devices
flutter run --dart-define-from-file=config.local.json
```

Copia `config.example.json` como `config.local.json` y configura tu clave pública de CARTO Basemaps para el mapa Positron. El archivo local está excluido de Git. `API_BASE_URL` permite cambiar el backend. Sin clave de CARTO se utiliza el proveedor alternativo configurado; consulta sus condiciones antes de publicar.

## Validar y compilar

```sh
flutter analyze
flutter test
flutter build apk --release --dart-define-from-file=config.local.json
```

El APK se genera en `build/app/outputs/flutter-apk/app-release.apk`. La firma de distribución debe configurarse antes de publicar en una tienda; no se incluyen certificados ni claves privadas.

## Estructura

- `lib/config`: API, mapas y perímetro de referencia.
- `lib/models`, `lib/services`, `lib/state`: datos, conexión y sesión.
- `lib/screens`, `lib/widgets`, `lib/theme`: pantallas y diseño compartido.
- `assets`: marca, ilustraciones y geometría del campus.
- `test`: pruebas de integración de contratos y reglas de presentación.
- `docs`: requisitos y estado de integración.

## Estado de integración

Autenticación, perfil, catálogo y observaciones utilizan los servicios implementados del backend. La experiencia, la gamificación y otras funciones pendientes se presentan sin inventar resultados. El perímetro del campus es una referencia de OpenStreetMap, no un límite institucional aprobado ni una validación del servidor.

Consulta [la revisión del SRS v0.3](docs/INTEGRACION_SRS_V03.md) para conocer contratos y pendientes. Las atribuciones de OpenStreetMap y CARTO deben mantenerse visibles.

## Contribuciones

Los cambios de funcionalidades se proponen mediante una rama y un pull request. No subir configuraciones locales, claves, dependencias descargadas ni compilaciones.
