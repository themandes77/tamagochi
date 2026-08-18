# NTI Tamagochi — PRE-EA 0.1.0

Identidad:
- Nombre visible: NTI Tamagochi
- Android applicationId: com.ntp.ntitamagochi
- iOS Bundle ID: com.ntp.ntitamagochi
- Version: 0.1.0+1
- Orientacion: vertical

## Android 12+
Android 12+ controla el splash nativo: se vera el icono de NTI sobre fondo violeta,
seguido por el Loading de Flutter. En Android anteriores se usa la ilustracion vertical aprobada.

## Generar keystore en Windows (PowerShell)
keytool -genkey -v `
  -keystore "$env:USERPROFILE\nti-tamagochi-release.jks" `
  -storetype JKS `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias ntitamagochi

Recomendacion: password aleatorio de 24-32 caracteres y guardado en gestor de contrasenas.

## Configurar firma
Copia:
android/key.properties.example
a:
android/key.properties

Sustituye los placeholders. En Windows, storeFile usa doble backslash.

NO compartas:
- android/key.properties
- archivos .jks
- passwords

## Build universal Release
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release

Resultado:
build/app/outputs/flutter-apk/app-release.apk

No uses --split-per-abi para esta primera distribucion interna universal.
