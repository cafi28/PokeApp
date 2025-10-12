# 🐱‍⚡️ PokeApp

Aplicación móvil desarrollada en **Flutter** que simula un **inicio de sesión** y una **pantalla principal de evaluaciones**, adaptada al contexto de una **colección de cartas Pokémon**.  
Proyecto académico para el ramo **Aplicaciones Móviles para IoT – INACAP (Primavera 2025)**.

---

## 🎯 Objetivo del proyecto

El objetivo fue implementar una aplicación Flutter que cumpla con los requerimientos de:
- **Login con validaciones y navegación.**
- **Pantalla de evaluaciones (en este caso, cartas Pokémon)** con:
  - Listado precargado.
  - Estados derivados (Pendiente / Completada / Vencida).
  - Filtros, búsqueda y orden.
  - Creación y eliminación de ítems.
  - Persistencia visual y navegación fluida.

---

## 🧩 Características principales

### 🔐 **Pantalla de Login**
- Validación de correo (debe incluir “@” y “.”).  
- Validación de contraseña (mínimo 6 caracteres).  
- Mensajes de error claros y bloqueos de envío si falla.  
- Transición visual fluida hacia la pantalla de bienvenida.  

### ⚡ **Pantalla de Bienvenida**
- Muestra el correo del usuario tras iniciar sesión.  
- Incluye animación de **Pikachu corriendo** 🏃‍♂️⚡ (animación bidireccional con `AnimationController`).  
- Redirige automáticamente a la pantalla principal tras unos segundos.

### 🗂️ **Pantalla principal – Colección de cartas Pokémon**
- Listado precargado con al menos 5 ítems (`CartaPokemon`).
- Cada carta tiene:
  - Nombre, número, notas, fecha agregada y opcionalmente fecha objetivo.
  - Estado derivado automático:  
    - 🟢 **Pendiente** (no tengo y no vencida).  
    - 🔴 **Vencida** (fecha pasada sin tener).  
    - ✅ **Completada** (tengo marcada como obtenida).
- **Filtros rápidos:** Todas / Pendientes / Completas.  
- **Búsqueda en tiempo real** por nombre, número o notas.  
- **Orden asc/desc** por fecha agregada u objetivo.  
- **Creación de nuevas cartas** (modal con validaciones y `DatePicker` en español).  
- **Eliminación con Swipe** + opción **“Deshacer”** (Snackbar con Undo).  
- **UI responsiva y limpia**, con esquema de colores ámbar tipo INACAP.

---

## 🧠 Tecnologías utilizadas

- **Flutter 3.35.4**
- **Dart**
- **Material Design 3**
- **Intl (fecha en español - es_CL)**
- **flutter_localizations**  
- **VS Code + Git + GitHub**

---

## 🧩 Estructura de carpetas

```
lib/
 ├── main.dart                 # Configuración base y localización
 ├── login_screen.dart         # Pantalla principal de Login
 ├── login_fields.dart         # Formulario de login + animación Pikachu
 └── pokemon_screen.dart       # Pantalla principal (cartas Pokémon)
```

---

## ✅ Cumplimiento de la rúbrica INACAP

| Criterio | Estado |
|-----------|---------|
| Construcción visual – Login | ✅ Destacado |
| Validaciones y mensajes | ✅ Destacado |
| Navegación post-login | ✅ Destacado |
| Render y layout del listado | ✅ Destacado |
| Estados derivados | ✅ Destacado |
| Búsqueda | ✅ Destacado |
| Filtros rápidos | ✅ Destacado |
| Creación con validaciones | ✅ Destacado |
| Marcar como completada | ✅ Destacado |
| Eliminación con Undo | ✅ Destacado |

**Resultado final:** 💯 *Cumple todos los requerimientos y criterios de evaluación.*

---

## 📸 Capturas sugeridas

Puedes agregar capturas aquí:
```
assets/screenshots/
```

Ejemplo:
- 🟡 `login_screen.png`
- 🟢 `welcome_pikachu.gif`
- 🔴 `cartas_screen.png`

---

## 👩‍💻 Autora

**Carolina Figueroa Aburto**  
Estudiante de Ingeniería en Informática – INACAP  
Primavera 2025  

> Proyecto académico desarrollado con dedicación, Pikachu y amor al código ⚡🐾

---

## 🧾 Licencia
Este proyecto es de uso educativo.  
Queda prohibida su distribución o copia sin autorización de la autora.
