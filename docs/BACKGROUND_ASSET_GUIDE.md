# Guía de fondos de habitación

Los fondos de NTI se guardan en `assets/images/backgrounds/` y se registran
como opciones en `lib/features/customization/data/default_customizations.dart`.

## Reglas visuales

- Formato vertical 9:16.
- Mantener libre el 55 % central para NTI.
- Mantener simple el 18 % superior para las estadísticas.
- Mantener libre el 22 % inferior para las acciones.
- Colocar decoración principalmente en los bordes.
- No incluir personajes, caras, texto, botones ni elementos de interfaz.
- Evitar marcas o personajes protegidos.

## Fondos actuales

- `Original`: fondo gris claro de la primera versión; no utiliza una imagen.
- `room_normal_anniversary.png`: habitación cálida y festiva.
- `room_techno.png`: habitación futurista con neón.
- `room_adventure.png`: habitación de exploración y aventura.

El selector visible durante desarrollo se compila únicamente en modo debug.
En la versión final, la tienda equipará el fondo mediante el mismo modelo
`ThemeOption`.
