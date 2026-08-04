# NT Tamagochi

Aplicación móvil hecha con Flutter y Flame. El objetivo es publicar una primera
versión Early Access para Android e iOS.

## Estado del proyecto

- Flutter fijado para el equipo: `3.44.8 stable`.
- Dart: `3.12.2`, incluido con Flutter.
- Android: compilación de depuración verificada en Windows.
- iOS: estructura incluida; la compilación requiere macOS con Xcode.
- Identificadores y firma de publicación: pendientes de la decisión del equipo.

## Preparar una computadora

1. Instala Git, Flutter `3.44.8`, VS Code y las extensiones recomendadas.
2. Para Android, instala Android Studio, Android SDK 36 y acepta las licencias.
3. Clona el repositorio en una carpeta local que no esté sincronizada por
   OneDrive, Dropbox o Google Drive.
4. Desde la raíz del proyecto, ejecuta:

```bash
flutter doctor
flutter pub get
flutter test
flutter run
```

Para iOS también se requiere una Mac con Xcode y CocoaPods.

## Ejecutar

Aplicación principal:

```bash
flutter run -t lib/main.dart
```

## Verificación antes de un Pull Request

Windows:

```powershell
.\scripts\verify.ps1
.\scripts\verify.ps1 -BuildAndroid
```

macOS o Linux:

```bash
bash scripts/verify.sh
bash scripts/verify.sh --build-android
```

## Trabajo en equipo

- `main`: versiones estables.
- `develop`: integración del equipo.
- `feature/<persona>-<tarea>`: trabajo individual.
- `release/<version>`: estabilización de una entrega.
- No se permiten cambios directos en `main` o `develop`.
- Toda integración se realiza mediante Pull Request y al menos una revisión.

Consulta [CONTRIBUTING.md](CONTRIBUTING.md) antes de comenzar y revisa la
[lista de publicación](docs/RELEASE_CHECKLIST.md) antes de generar una versión.
