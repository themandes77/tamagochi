# Guía de colaboración

## Versiones compartidas

Todo el equipo debe utilizar Flutter `3.44.8 stable`. No se actualiza Flutter,
Dart, Flame ni otra dependencia dentro de una rama de funcionalidad. Las
actualizaciones se hacen en un Pull Request independiente.

`pubspec.lock` forma parte del repositorio y no debe eliminarse.

## Protección en GitHub

Cuando estos archivos lleguen a GitHub, el administrador debe proteger `main`
y `develop` con estas reglas:

- Exigir Pull Request antes de fusionar.
- Exigir al menos una aprobación.
- Exigir los checks **Format, analyze and test** y
  **Build Android debug APK**.
- Bloquear `force push` y eliminación de las ramas.
- Resolver conversaciones de revisión antes de fusionar.

## Ramas

- `main`: versión estable y potencialmente publicable.
- `develop`: última integración aprobada.
- `feature/samuel-pet-core`: estado, necesidades y guardado de la mascota.
- `feature/marco-falling-minigame`: minijuego y resultado de monedas.
- `feature/azael-store-customization`: tienda y personalización.
- `release/early-access-0.1.0`: correcciones de la primera entrega.

Una rama nueva siempre parte de la versión actual de `develop`:

```bash
git fetch origin
git switch develop
git pull --ff-only origin develop
git switch -c feature/nombre-tarea
git push -u origin feature/nombre-tarea
```

Para recibir cambios nuevos de integración:

```bash
git fetch origin
git switch feature/nombre-tarea
git merge origin/develop
```

No se debe usar `push --force` en ramas compartidas.

## Commits

Haz commits pequeños y con una sola intención. Prefijos recomendados:

- `feat:` funcionalidad nueva.
- `fix:` corrección de un error.
- `test:` pruebas.
- `docs:` documentación.
- `chore:` configuración o mantenimiento.

Ejemplo: `feat: add store inventory`.

## Pull Requests

1. El destino normal es `develop`, nunca `main`.
2. Explica qué cambió y cómo probarlo.
3. Incluye captura o video cuando cambie la interfaz.
4. Comprueba que no haya secretos, rutas personales o archivos generados.
5. Ejecuta `scripts/verify.ps1` o `scripts/verify.sh`.
6. Espera que GitHub Actions termine correctamente.
7. Solicita la revisión de al menos otra persona.
8. Usa **Squash and merge** para mantener un historial sencillo.

Si existe un conflicto que involucra código de otra persona, se resuelve con
esa persona; no se elimina código para hacer desaparecer el conflicto.

## Contratos entre módulos

- El núcleo expone el estado de la mascota y el mecanismo de guardado.
- El minijuego devuelve puntuación y monedas; no escribe directamente en la
  tienda.
- La tienda usa un repositorio para monedas, inventario y elementos equipados.
- La interfaz consume contratos; no depende de implementaciones internas de
  otro módulo.

Los cambios a un contrato compartido deben acordarse antes de implementarse y
quedar descritos en el Pull Request.

## Archivos que nunca se suben

- `.env` y credenciales.
- `key.properties`, certificados, perfiles y llaves de firma.
- `local.properties` o rutas del SDK.
- `.dart_tool/`, `build/`, `Pods/` y otros archivos generados.
- Configuración que contenga rutas absolutas de una computadora.
