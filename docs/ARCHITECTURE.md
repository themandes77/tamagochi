# Arquitectura de la aplicación

## Objetivo

Permitir que tres personas desarrollen módulos distintos sin depender de la
implementación interna de los demás.

## Capas por funcionalidad

Cada funcionalidad nueva debe organizarse, cuando aplique, de esta forma:

```text
lib/features/<feature>/
  domain/        modelos y contratos sin interfaz
  data/          almacenamiento y fuentes de datos
  application/   reglas y coordinación de casos de uso
  presentation/  widgets, pantallas y control de interacción
```

Las dependencias apuntan hacia el dominio:

```text
presentation -> application -> domain
data ------------------------> domain
```

El dominio no debe importar widgets, pantallas ni una base de datos concreta.

## Responsabilidades

### Núcleo de mascota

- Estado de hambre, salud, energía, limpieza y diversión.
- Paso del tiempo y reglas de actualización.
- Contrato de persistencia compartida.

### Minijuego

- Ciclo del minijuego, puntuación y finalización.
- Devuelve un resultado con las monedas obtenidas.
- No modifica directamente el inventario o la tienda.

### Tienda y personalización

- Catálogo, monedas, compras e inventario.
- Aspecto y tema equipados.
- Acceso a los datos mediante `StoreRepository`.

## Integración

La aplicación principal será el composition root: crea las implementaciones de
los repositorios, controladores y pantallas. Los módulos no se crean entre sí ni
acceden directamente a archivos internos de otro módulo.

Un cambio a un modelo o contrato compartido requiere:

1. Acuerdo del equipo.
2. Prueba que describa el comportamiento.
3. Pull Request pequeño hacia `develop`.
4. Actualización de los consumidores afectados.
