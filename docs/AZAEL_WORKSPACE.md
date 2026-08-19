# Espacio de trabajo de Azael

Esta rama prepara el módulo de economía, tienda, inventario, skins y temas sin
depender de la pantalla principal del Tamagotchi.

## Rama

`feature/azael-store-customization`

La rama parte del `origin/main` actualizado. No hagas cambios directamente en
`main`.

## Cómo abrir la vista independiente

Desde la raíz del proyecto:

```powershell
flutter pub get
flutter run -t lib/dev/azael_store_preview.dart
```

En VS Code también puedes seleccionar la configuración
`Azael — Store preview` y pulsar `F5`.

La vista utiliza un repositorio en memoria. Esto permite desarrollar y probar
la tienda sin bloquearse por la persistencia general que conectará el equipo.

## Archivos que pertenecen a Azael

```text
lib/features/store/
lib/features/customization/
lib/dev/azael_store_preview.dart
test/features/store/
assets/Slimes/
assets/themes/
```

Evita modificar sin coordinación:

```text
lib/main.dart
lib/nti_tamagochi.dart
lib/actors/player.dart
pubspec.yaml
pubspec.lock
```

`pubspec.yaml` se modifica en esta rama solamente para registrar
`assets/Slimes/`.

## Contrato disponible

### StoreController

- `coins`: saldo actual.
- `purchase(itemId)`: compra un artículo.
- `equip(itemId)`: equipa una skin o tema que ya pertenece al jugador.
- `addCoins(amount)`: recibe recompensas de un minijuego.
- `ownedItemIds`: inventario.
- `selectedSkin` y `selectedTheme`: selección actual.

### StoreRepository

Es la interfaz para persistir `StoreSnapshot`. La vista de desarrollo usa
`InMemoryStoreRepository`. Posteriormente se puede crear un adaptador con la
solución de guardado elegida por el equipo sin cambiar la tienda.

## Sprites

El catálogo usa `assets/Slimes/slime_idle2.png`.

- Cada fotograma lógico mide `80 × 72`.
- Cada color corresponde a una fila.
- Morado: fila 0.
- Naranja: fila 2.
- Azul: fila 3.
- Verde: fila 4.

La UI actual usa formas de color como placeholder. La siguiente tarea visual es
crear un componente que recorte y anime la fila adecuada del sprite sheet.

## Comandos de verificación

Ejecuta antes de cada Pull Request:

```powershell
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
git status --short
git diff --check
```

## Lista de trabajo

- [ ] Sustituir los previews de color por sprites animados.
- [ ] Diseñar el fondo Techno.
- [ ] Ajustar nombres, precios y balance con el equipo.
- [ ] Añadir confirmación antes de comprar.
- [ ] Definir sonidos de compra, error y equipamiento.
- [ ] Integrar recompensas de `GameResult`.
- [ ] Conectar `StoreRepository` con la persistencia compartida.
- [ ] Integrar la tienda como overlay sin modificar directamente el núcleo.
- [ ] Probar en un teléfono Android.

## Flujo de Git

1. Actualiza tu rama desde la rama de integración acordada.
2. Trabaja en una tarea pequeña.
3. Ejecuta las verificaciones.
4. Revisa `git diff`.
5. Haz un commit descriptivo.
6. Publica la rama.
7. Abre un Pull Request hacia `develop` cuando exista; mientras tanto, no lo
   abras hacia `main` sin acordarlo con el equipo.
