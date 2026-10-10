# Entregable DevOps en AWS

Esta rama adapta la aplicación `saludos` para la arquitectura AWS del
entregable. La aplicación conserva tres imágenes publicables para cumplir el
flujo de CI, pero en producción PostgreSQL se ejecutará en Amazon RDS y no como
un contenedor permanente.

La arquitectura detallada está documentada en
[`docs/arquitectura-aws.md`](docs/arquitectura-aws.md) y puede crearse de forma
repetible con la plantilla de
[`infrastructure/cloudformation/main.yml`](infrastructure/cloudformation/main.yml).
La guía de validación, despliegue, registro del runner y eliminación se
encuentra en [`infrastructure/README.md`](infrastructure/README.md).

## Flujo de trabajo

- `develop`: ejecuta checkout, build y pruebas.
- `main`: vuelve a ejecutar CI, etiqueta las imágenes y las publica en Docker
  Hub. Al finalizar correctamente, habilita el flujo de CD.
- Los tags inmutables usan `<run-number>-<short-sha>`; `latest` se mantiene por
  requisito del taller.

## Ejecución local

Docker Compose se usa solamente para desarrollo y pruebas locales. El pipeline
de GitHub Actions construye y despliega mediante comandos Docker individuales.

```bash
cd github
docker compose -f compose.local.yml up --build
```

Abra `http://localhost:8080` y pruebe:

```bash
curl --fail http://localhost:8080/health
curl --fail http://localhost:8080/api/health
curl --fail http://localhost:8080/api/saludo
```

Para detener el ambiente local:

```bash
docker compose -f compose.local.yml down --volumes
```

## Configuración

El backend lee la conexión PostgreSQL desde variables de entorno:

- `DB_HOST`
- `DB_PORT`
- `DB_NAME`
- `DB_USER`
- `DB_PASSWORD`
- `DB_SSLMODE`

El frontend genera su configuración de Nginx al iniciar mediante:

- `BACKEND_HOST`
- `BACKEND_PORT`

Nunca se deben guardar contraseñas, tokens de GitHub ni credenciales de AWS en
el repositorio.

## Secretos de GitHub requeridos

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

## Variables de GitHub para CD

- `AWS_REGION`
- `BACKEND_INSTANCE_ID`
- `BACKEND_PRIVATE_DNS`
- `FRONTEND_INSTANCE_IDS` (IDs separados por espacios)
- `APP_URL`

La autenticación de AWS se realizará mediante el rol IAM asociado a la EC2 del
runner. No se crearán access keys permanentes para el usuario root.

CD utiliza AWS Systems Manager para ejecutar los scripts de `github/deploy/`
en las instancias, sin abrir el puerto SSH a Internet. Una ejecución manual de
CD permite indicar un tag anterior y funciona como rollback.
