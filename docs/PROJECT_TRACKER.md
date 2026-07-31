# Control del proyecto NT Tamagochi

Última actualización: 31 de julio de 2026
Objetivo de Early Access: antes del 10 de agosto de 2026

Este documento es la fuente única para saber qué está terminado, qué está en
progreso, quién es responsable y qué bloquea al equipo.

## Estados

| Estado | Significado |
|---|---|
| ✅ Terminado | Código y pruebas listos |
| 🟡 En progreso | Trabajo iniciado, todavía no entregable |
| ⏳ Pendiente | Aún no iniciado |
| ⛔ Bloqueado | Necesita una decisión o trabajo externo |

## Resumen

| Sprint | Objetivo | Estado |
|---|---|---|
| Sprint 1 | Base de personalización y recursos visuales | 🟡 En cierre |
| Sprint 2 | Tienda funcional, equipamiento y guardado | 🟡 En progreso |
| Sprint 3 | Integración de los módulos de los tres integrantes | ⏳ Pendiente |
| Sprint 4 | Pruebas, correcciones y Early Access | ⏳ Pendiente |

## Sprint 1 — Personalización visual

Responsable: Azael  
Rama: `feature/azael-store-customization`

La implementación está terminada. El sprint no se considera cerrado hasta que
el Pull Request esté revisado e integrado.

| ID | Tarea | Estado |
|---|---|---|
| AZ-001 | Preparar Flutter, dependencias y rama de trabajo | ✅ Terminado |
| AZ-002 | Conservar el aspecto original de NTI | ✅ Terminado |
| AZ-003 | Crear aspectos Aniversario, Techno y Aventurero | ✅ Terminado |
| AZ-004 | Mantener una estructura redonda en los aspectos nuevos | ✅ Terminado |
| AZ-005 | Separar ojos y boca para permitir animaciones | ✅ Terminado |
| AZ-006 | Añadir parpadeo, mirada, respiración, habla y diálogo | ✅ Terminado |
| AZ-007 | Crear fondos Aniversario, Techno y Aventura | ✅ Terminado |
| AZ-008 | Recuperar el fondo Original como opción predeterminada | ✅ Terminado |
| AZ-009 | Crear selectores temporales de aspectos y fondos | ✅ Terminado |
| AZ-010 | Registrar artículos y temas en el catálogo | ✅ Terminado |
| AZ-011 | Documentar reglas para nuevos aspectos y fondos | ✅ Terminado |
| AZ-012 | Ejecutar análisis, pruebas y compilación web | ✅ Terminado |
| AZ-013 | Hacer commit del Sprint 1 | ✅ Terminado |
| AZ-014 | Subir la rama a GitHub | ⏳ Pendiente |
| AZ-015 | Abrir Pull Request y solicitar revisión | ⏳ Pendiente |
| AZ-016 | Integrar el Pull Request en la rama acordada | ⏳ Pendiente |

### Criterio de cierre del Sprint 1

- [x] La aplicación compila.
- [x] Las 14 pruebas pasan.
- [x] `flutter analyze` no reporta problemas.
- [x] Original es el aspecto y fondo predeterminados.
- [x] Los cuatro aspectos y cuatro fondos se pueden seleccionar.
- [x] Los cambios están guardados en un commit.
- [ ] La rama está publicada.
- [ ] El equipo revisó e integró el Pull Request.

## Sprint 2 — Tienda funcional

Responsable principal: Azael  
Rama: `feature/azael-store-functional`
Base local: commit `9ddda1e` del Sprint 1.

| ID | Tarea | Estado | Dependencia |
|---|---|---|---|
| AZ-101 | Sustituir el selector temporal por acceso real a la tienda | ✅ Terminado | Ninguna |
| AZ-102 | Mostrar los aspectos y fondos reales en el catálogo | ✅ Terminado | Ninguna |
| AZ-103 | Acordar precios y balance de monedas | ⏳ Pendiente | Decisión del equipo |
| AZ-104 | Añadir confirmación antes de comprar | ⏳ Pendiente | AZ-102 |
| AZ-105 | Comprar artículos y descontar monedas | ✅ Terminado | Precios provisionales hasta AZ-103 |
| AZ-106 | Equipar aspectos y fondos comprados | ✅ Terminado | AZ-102 |
| AZ-107 | Conectar el equipamiento con NTI y la habitación | ✅ Terminado | AZ-106 |
| AZ-108 | Guardar monedas, compras y selección localmente | ⏳ Pendiente | AZ-105 |
| AZ-109 | Restaurar el estado al abrir la aplicación | ⏳ Pendiente | AZ-108 |
| AZ-110 | Recibir recompensas de los minijuegos | ⏳ Pendiente | Contrato de Marco |
| AZ-111 | Añadir pruebas de compra, equipamiento y persistencia | ⏳ Pendiente | AZ-105 a AZ-109 |
| AZ-112 | Verificar comportamiento compatible con Android e iOS | ⏳ Pendiente | AZ-111 |
| AZ-113 | Revisar proporción circular de los aspectos | ✅ Terminado | AZ-102 |
| AZ-114 | Crear vista previa reutilizable de NTI animado | ✅ Terminado | AZ-113 |
| AZ-115 | Añadir microinteracciones a tienda y personalización | ✅ Terminado | AZ-114 |
| AZ-116 | Validar rendimiento de las animaciones | 🟡 En progreso | AZ-115 |

### Avance del Sprint 2

- `AZ-101`: el botón `TIENDA` abre la tienda como overlay sobre la aplicación
  real, pausa el juego y lo reanuda al cerrar.
- `AZ-102`: el catálogo provisional de Slimes fue sustituido por los aspectos
  Original, Aniversario, Techno y Aventurero y por los cuatro fondos reales.
- La vista previa usa los PNG cuadrados sin deformarlos y añade respiración,
  parpadeo, mirada, habla, cambios animados y microinteracciones.
- Los artículos equipados actualizan a NTI y el fondo de la habitación al
  cerrar la tienda.
- Los precios actuales son provisionales hasta que el equipo cierre `AZ-103`.
- La tienda utiliza temporalmente `InMemoryStoreRepository`; el guardado entre
  reinicios se implementará en `AZ-108`.

### Criterio de cierre del Sprint 2

- La tienda se abre desde la aplicación real.
- Original permanece gratuito y disponible.
- No se puede comprar sin monedas suficientes.
- Un artículo comprado puede equiparse.
- Las compras y el equipamiento sobreviven al reinicio.
- Los selectores temporales sólo existen en modo debug.
- Análisis, pruebas y compilaciones Android/iOS pasan.
- Pull Request revisado e integrado.

## Trabajo paralelo del equipo

Estas áreas permiten que los tres integrantes avancen sin esperar a que otro
termine todo su módulo.

| Integrante | Área principal | Entregables |
|---|---|---|
| Samuel | Pantalla principal y cuidados | Limpieza, comida, diversión, salud, energía, sonidos, diálogos e inventario |
| Marco | Minijuegos | Doodle Jump, recolección en caída y resultado con recompensa |
| Azael | Personalización y economía | Aspectos, fondos, monedas, tienda, inventario y equipamiento |

### Contratos que deben acordarse al iniciar el Sprint 2

| Contrato | Responsable de proponerlo | Consumidores |
|---|---|---|
| `GameResult` con cantidad de monedas ganadas | Marco | Azael |
| Acción para abrir/cerrar la tienda | Samuel | Azael |
| Estado compartido de monedas e inventario | Azael | Samuel y Marco |

Cada responsable puede trabajar con datos simulados hasta que el contrato real
esté disponible. Esto evita bloquear el trabajo paralelo.

## Sprint 3 — Integración

| ID | Tarea | Responsable | Estado |
|---|---|---|---|
| TEAM-201 | Integrar pantalla principal, tienda y minijuegos | Equipo | ⏳ Pendiente |
| TEAM-202 | Unificar navegación y estado compartido | Equipo | ⏳ Pendiente |
| TEAM-203 | Resolver conflictos y eliminar datos simulados | Equipo | ⏳ Pendiente |
| TEAM-204 | Verificar guardado después de cuidados y minijuegos | Equipo | ⏳ Pendiente |
| TEAM-205 | Probar el flujo completo de una sesión | Equipo | ⏳ Pendiente |

## Sprint 4 — Early Access

| ID | Tarea | Responsable | Estado |
|---|---|---|---|
| REL-301 | Corregir errores críticos y bloqueos | Equipo | ⏳ Pendiente |
| REL-302 | Revisar rendimiento y tamaño de imágenes | Equipo | ⏳ Pendiente |
| REL-303 | Probar Android en emulador o dispositivo | Equipo | ⏳ Pendiente |
| REL-304 | Probar iOS en macOS y iPhone | Equipo | ⏳ Pendiente |
| REL-305 | Preparar icono, nombre, versión y notas | Equipo | ⏳ Pendiente |
| REL-306 | Generar build candidata de Early Access | Equipo | ⏳ Pendiente |

## Regla de actualización

1. Al comenzar una tarea, cambiarla a `🟡 En progreso`.
2. Si se bloquea, marcar `⛔ Bloqueado` y escribir la dependencia.
3. Al terminar código y pruebas, marcar `✅ Terminado`.
4. Incluir los ID de tareas en commits y Pull Requests.
5. Actualizar este archivo antes de solicitar revisión.

Ejemplo de commit:

```text
AZ-105 Implementar compra de artículos con monedas
```
