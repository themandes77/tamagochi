# Lista para Early Access

Esta lista separa el desarrollo diario de las decisiones necesarias para
publicar en Android e iOS.

## Identidad pendiente

- [ ] Nombre público definitivo.
- [ ] Nombre interno del paquete Dart.
- [ ] `applicationId` y `namespace` únicos de Android.
- [ ] Bundle ID único de iOS.
- [ ] Icono y pantalla de lanzamiento definitivos.
- [ ] Orientación: vertical o vertical/horizontal.
- [ ] Recursos visuales, sonidos y fuentes con licencia o creación original.

## Calidad

- [ ] `dart format --output=none --set-exit-if-changed lib test`.
- [ ] `flutter analyze` sin problemas.
- [ ] `flutter test` completo.
- [ ] Compilación Android desde una copia limpia del repositorio.
- [ ] Compilación iOS desde una Mac.
- [ ] Prueba en al menos un Android físico.
- [ ] Prueba en al menos un iPhone físico.
- [ ] Verificar instalación nueva, guardado, cierre y reapertura.
- [ ] Verificar distintos tamaños de pantalla y áreas seguras.
- [ ] Revisar permisos y política de privacidad.

## Android

- [ ] Sustituir `com.example.flutter_application_1`.
- [ ] Sustituir el nombre visible `flutter_application_1`.
- [ ] Crear la llave de carga fuera del repositorio.
- [ ] Configurar firma release sin subir `key.properties` ni la llave.
- [ ] Generar `flutter build appbundle --release`.
- [ ] Distribuir primero mediante prueba interna de Google Play.

## iOS

- [ ] Sustituir `com.example.flutterApplication1`.
- [ ] Sustituir `Flutter Application 1`.
- [ ] Seleccionar Apple Developer Team y firma en Xcode.
- [ ] Confirmar la versión mínima de iOS y los plugins.
- [ ] Generar y validar el archivo desde macOS.
- [ ] Distribuir primero mediante TestFlight.

## Versión

- [ ] Acordar la versión Early Access, recomendada `0.1.0+1`.
- [ ] Crear `release/early-access-0.1.0` desde `develop`.
- [ ] Aceptar solamente correcciones críticas en la rama release.
- [ ] Fusionar la versión aprobada a `main` y etiquetarla.
- [ ] Regresar las correcciones necesarias de `main` a `develop`.
