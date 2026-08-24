# BioJaveriana - Backend (API)

## Información

Este repositorio contiene el código del backend de **BioJaveriana**, desarrollado en **Java utilizando Spring Boot** y desplegado en un VPS en la nube.

Para obtener información sobre el desarrollo y las contribuciones al proyecto, consulte las secciones correspondientes a continuación.

## Desarrollo

Para el desarrollo local se requieren los siguientes componentes:

- Tener instalada una versión compatible de **Docker (>= 29)**.
- Tener instalada la extensión **Docker Dev Containers** en el entorno de desarrollo.

**Dev Containers** es una herramienta que permite desarrollar dentro de un entorno de Docker preconfigurado. Esto garantiza que todos los desarrolladores utilicen versiones y dependencias consistentes, evitando problemas relacionados con diferencias entre entornos locales.

### Configuración

Clone el repositorio y ábralo utilizando su editor de código compatible con Dev Containers.

Una vez abierto el proyecto, utilice la opción:

> **Dev Containers: Reopen in Container**

El entorno de desarrollo se encargará de crear el contenedor necesario para el backend y de iniciar los servicios requeridos, incluyendo una instancia local de **PostgreSQL**.

La estructura general del entorno es:

```text
┌───────────────────────────────┐
│        Dev Container          │
│                               │
│        Spring Boot API        │
└───────────────┬───────────────┘
                │
                │ PostgreSQL
                ▼
┌───────────────────────────────┐
│       PostgreSQL Container    │
│                               │
│       Base de datos local     │
└───────────────────────────────┘
```

Una vez iniciado el contenedor, el proyecto puede ejecutarse normalmente utilizando las herramientas de desarrollo disponibles dentro del entorno.

### Dependencias
Las dependencias del proyecto se administran mediante pub y se encuentran definidas en el archivo `pubspec.yaml`.

Para instalar las dependencias:
```
flutter pub get
```

Para actualizar las dependencias dentro de las restricciones especificadas en `pubspec.yaml`:
```
flutter pub upgrade
```

Las dependencias no deben modificarse manualmente dentro del directorio `.pub-cache`.

### Ejecución
Para verificar que Flutter esté correctamente configurado:
```
flutter doctor
```

Para comprobar los dispositivos disponibles:
```
flutter devices
```

La aplicación puede ejecutarse utilizando:
```
flutter run
```

También puede utilizarse la opción Run and Debug del editor.

Para ejecutar la aplicación en un dispositivo Android conectado, asegúrese de que la depuración USB esté habilitada y que el dispositivo sea reconocido por:

```
adb devices
```

> [!NOTE]
> El desarrollo dentro de un Dev Container requiere que el dispositivo Android o emulador sea accesible desde el entorno de Docker. Dependiendo del sistema operativo y la configuración utilizada, puede ser necesario configurar el acceso al dispositivo.


###
## Contribuciones

Para contribuir al repositorio se deben realizar Pull Requests (PR).

Los cambios pequeños y de bajo riesgo pueden realizarse directamente sobre `main`, siempre que esto sea apropiado para el cambio.

Para cambios más grandes, nuevas funcionalidades o modificaciones que puedan afectar otras partes del sistema, se debe crear una rama independiente a partir de `main`.

Las ramas de desarrollo deben mantenerse actualizadas con `main` durante el desarrollo para reducir conflictos al momento de realizar el merge.

Una vez finalizado el desarrollo:

1. Verifique que el proyecto compile correctamente.
2. Ejecute las pruebas disponibles.
3. Actualice la rama con los cambios más recientes de `main`.
4. Cree un Pull Request hacia `main`.
5. Espere la revisión y aprobación correspondiente antes de realizar el merge.

Solamente la rama `main` estará desplegada en el ambiente de producción.

### Convenciones de ramas

Se recomienda utilizar nombres descriptivos para las ramas. Por ejemplo:

```
feature/nombre-de-la-funcionalidad
fix/descripcion-del-error
refactor/descripcion-del-cambio
```

Las ramas deben tener un único propósito y evitar mezclar funcionalidades o correcciones no relacionadas.

> [!WARNING]
> Si encuentras un error en tu rama, corrígelo en una rama de corrección (hotfix/bugfix), haz un Pull Request hacia `main` y luego actualiza tu rama. Ramas marcadas como hotfix/bugfix cuentan con prioridad.

### Convenciones de commits

Los mensajes de commit deben escribirse en **tiempo presente** (modo imperativo) y, cuando sea posible, seguir el formato de **Conventional Commits**:

Los tipos más comunes son:

| Tipo | Uso |
|------|-----|
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de un error |
| `refactor` | Cambios en el código que no corrigen errores ni agregan funcionalidades (reestructuración interna) |
| `chore` | Tareas de mantenimiento (dependencias, configuración, scripts, etc.) que no afectan la lógica de la aplicación |
| `docs` | Cambios en la documentación |
| `test` | Agregar o corregir pruebas |
| `style` | Cambios de formato (espacios, indentación, etc.) que no afectan la lógica |
| `perf` | Cambios que mejoran el rendimiento |

Ejemplos:
```
feat: agrega endpoint para consultar muestras por usuario
fix: corrige validación de fecha en formulario de registro
refactor: simplifica lógica de autenticación
chore: actualiza dependencias de Spring Boot
docs: actualiza instrucciones de configuración del Dev Container
```

Los commits pueden estar tanto en español como en ingles, pero se recomienda utilizar ingles.

> [!TIP]
> Usar tiempo presente ayuda a mantener consistencia en el historial: el mensaje debe completar la frase "Este commit **hace** ...", no "Este commit **hizo** ...".