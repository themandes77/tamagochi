# Guía de recursos para trajes de NTI

## Plantilla maestra

`assets/images/outfits/nti_anniversary.png` define la estructura visual de
todos los trajes:

- Lienzo cuadrado de 1254 × 1254 píxeles.
- Cuerpo compacto, circular y con la parte inferior redondeada.
- Misma escala, centro, pose frontal, iluminación y material morado.
- Una sola antena flotante, conservando posición y proporciones.
- Rostro vacío y liso: los ojos y la boca se dibujan y animan desde Flame.

`assets/images/outfits/nti_original.png` conserva esa misma estructura sin
ropa ni accesorios y es la apariencia inicial de NTI.

## Regla para crear un traje

Solo se pueden cambiar los accesorios y la ropa. No se debe regenerar,
estirar, estrechar ni recolorear el cuerpo. El PNG final debe conservar el
lienzo cuadrado y tener fondo transparente.

Las prendas de la cabeza deben mantenerse por encima del área de los ojos y
las prendas del pecho por debajo de la boca. Las coordenadas faciales de cada
traje se registran en:

`lib/features/customization/domain/nti_outfit.dart`

## Validación antes de agregarlo

1. Comparar la silueta con `nti_anniversary.png`.
2. Confirmar que el cuerpo sea circular, no ovalado ni con forma de frijol.
3. Confirmar que no existan ojos o boca pintados en el PNG.
4. Revisar transparencia, bordes y ausencia de fondo verde.
5. Ejecutar `flutter analyze` y `flutter test`.
