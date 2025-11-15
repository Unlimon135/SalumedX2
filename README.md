# SalumedX2

SalumedX2 es una aplicación backend diseñada para servir como API central para una web que permite comparar precios de productos farmacéuticos en distintas farmacias. El proyecto expone datos a través de REST, GraphQL y WebSocket, ofreciendo flexibilidad para distintos clientes o interfaces.

---

## Características principales

- Endpoints REST** para recursos como productos, farmacias, precios, etc.
- Esquema GraphQL para consultas más flexibles y anidadas.
- Soporte por WebSocket para notificaciones en tiempo real (por ejemplo, actualizaciones de precio).
- Modelos bien estructurados para representar productos farmacéuticos, catálogos de farmacia y variaciones de precio.
- Arquitectura modular: separa la lógica de modelo (`models/`), servicio (`service/`) y esquema GraphQL (`schema/` y `resolvers/`).

---

## 🚀 Instalación y ejecución

A continuación, los pasos para levantar el servidor localmente:

1. Clona el repositorio:

   ```
   git clone https://github.com/Unlimon135/SalumedX2.git
   cd SalumedX2
   ```

2. Instala dependencias:

    ```
    bundle install
    ```

3. Configura variables de entorno (por ejemplo, base de datos, credenciales, puerto, etc.). Puedes crear un archivo .env en config/ con tus parámetros.

4. Corre las migraciones o inicializa la base de datos.

5. Inicia el servidor:
    ```
    ruby app.rb
    ```

6. Verifica que esté corriendo; deberías poder acceder a:

    - Endpoints REST: http://localhost:PORT/api/...

    - GraphQL: http://localhost:PORT/graphql

    - WebSocket: ws://localhost:PORT/... (dependiendo de cómo lo hayas configurado)