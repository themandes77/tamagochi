# Espacio de trabajo de Azael

Esta rama prepara el módulo de economía, tienda, inventario, trajes y fondos sin
depender de la pantalla principal del Tamagotchi.

## Rama

`feature/azael-store-functional`

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
assets/images/outfits/
assets/images/backgrounds/
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
- `equip(itemId)`: equipa un traje o fondo que ya pertenece al jugador.
- `addCoins(amount)`: recibe recompensas de un minijuego.
- `ownedItemIds`: inventario.
- `selectedOutfit` y `selectedTheme`: selección actual.

### StoreRepository

Es la interfaz para persistir `StoreSnapshot`. La vista de desarrollo usa
`InMemoryStoreRepository`. Posteriormente se puede crear un adaptador con la
solución de guardado elegida por el equipo sin cambiar la tienda.

## Assets visuales

El catálogo usa los cuatro PNG cuadrados de `assets/images/outfits/` y los
fondos de `assets/images/backgrounds/`. La vista previa no altera la relación de
aspecto: el cuerpo, los ojos y la boca se componen por capas. Las animaciones de
respiración, parpadeo, mirada y habla se producen en código para no necesitar un
archivo distinto por cada fotograma.

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

- [x] Sustituir los previews provisionales por los trajes reales animados.
- [x] Integrar los fondos Original, Aniversario, Techno y Aventura.
- [ ] Ajustar nombres, precios y balance con el equipo.
- [ ] Añadir confirmación antes de comprar.
- [ ] Definir sonidos de compra, error y equipamiento.
- [ ] Integrar recompensas de `GameResult`.
- [ ] Conectar `StoreRepository` con la persistencia compartida.
- [x] Integrar la tienda como overlay coordinado con el núcleo.
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
