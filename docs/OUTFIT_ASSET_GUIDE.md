# Guía de recursos para trajes de NTI

## Plantilla maestra

`assets/images/outfits/nti_body_master.png` es el único cuerpo de NTI y se
reutiliza sin cambios en todos los trajes:

- Lienzo cuadrado de 1254 × 1254 píxeles.
- Cuerpo completamente esférico, tan ancho como alto, basado en la referencia
  visual aprobada por el equipo.
- Misma escala, centro, pose frontal, iluminación y material morado.
- Una sola antena flotante, conservando posición y proporciones.
- Rostro vacío y liso: los ojos y la boca se dibujan y animan desde Flame.

Los archivos `nti_anniversary_overlay.png`, `nti_techno_overlay.png` y
`nti_adventurer_overlay.png` contienen únicamente ropa y accesorios sobre un
fondo transparente. La variante Original no utiliza overlay.

Flutter y Flame componen siempre las capas en este orden:

1. `nti_body_master.png`.
2. Overlay opcional del traje.
3. Ojos y boca animados.

## Regla para crear un traje

Solo se pueden cambiar los accesorios y la ropa. No se debe copiar, regenerar,
estirar, estrechar ni recolorear el cuerpo dentro de un overlay. El PNG final
debe conservar el lienzo de 1254 × 1254 y tener fondo transparente.

Las prendas de la cabeza deben mantenerse por encima del área de los ojos y
las prendas del pecho por debajo de la boca. Las coordenadas faciales de cada
traje se registran en:

`lib/features/customization/domain/nti_outfit.dart`

## Validación antes de agregarlo

1. Confirmar que el overlay no incluya ningún píxel del cuerpo morado.
2. Superponerlo sobre `nti_body_master.png` sin moverlo ni redimensionarlo.
3. Confirmar que no existan ojos o boca pintados en el PNG.
4. Revisar transparencia, bordes y ausencia de fondo verde.
5. Ejecutar `flutter analyze` y `flutter test`.
