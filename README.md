# CiberVicio - Sistema de Gestión de Cibercafé

CiberVicio es una solución integral diseñada para la gestión moderna de centros de ocio digital y cibercafés. Este proyecto combina un backend robusto en Lua con clientes multiplataforma para ofrecer una experiencia fluida tanto a administradores como a usuarios finales.

---

## Características Principales

- **Gestión Centralizada**: Panel de control web para administrar usuarios, equipos y reservas en tiempo real.
- **Cliente de PC (Kiosko)**: Interfaz bloqueada que controla el acceso de los usuarios y sincroniza el tiempo de sesión.
- **App Móvil (Android)**: Permite a los usuarios realizar reservas, consultar disponibilidad y gestionar su perfil desde cualquier lugar.
- **Control Remoto**: Capacidad de bloquear/desbloquear equipos directamente desde el servidor.
- **Base de Datos Robusta**: Integración completa con MySQL para asegurar la integridad de los datos.

---

## Tecnologías Utilizadas

- **Backend**: [Luvit](https://luvit.io/) (Runtime asíncrono de Lua basado en libuv).
- **Base de Datos**: MySQL / MariaDB.
- **Frontend Administrativo**: HTML5, Vanilla CSS, JavaScript.
- **App Móvil**: Flutter / Dart.
- **Control de Equipos**: Lua / Love2D (Kiosko PC).

---

## Estructura del Proyecto

- `/backend`: Servidor API y lógica de negocio en Luvit.
- `/cliente_pc`: Código del software de control para los puestos del cibercafé.
- `/cliente_android`: Código fuente de la aplicación móvil para usuarios.
- `/assets`: Recursos gráficos y multimedia.
- `database.sql`: Esquema de la base de datos necesario para el despliegue.

---

## Licencia

Este proyecto es parte de un trabajo intermodular. Consulta el archivo license.txt para más detalles.

---

Desarrollado por [lucianbudail-dotcom](https://github.com/lucianbudail-dotcom)
