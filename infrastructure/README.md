# Infraestructura como código

La plantilla `cloudformation/main.yml` crea la arquitectura completa del
entregable en una pila independiente. No modifica el VPC `aws-algecas` ni otros
recursos que ya existan en la cuenta.

## Recursos creados

- VPC `10.0.0.0/24`, Internet Gateway, NAT Gateway y tablas de rutas.
- Dos subredes públicas para el ALB y los frontends.
- Una subred privada para el backend y dos subredes privadas para RDS.
- Tres EC2 Amazon Linux 2023 con Docker y Systems Manager.
- Runner de GitHub preinstalado, pendiente únicamente de registrarlo.
- RDS PostgreSQL privado con credencial administrada por Secrets Manager.
- Roles IAM con permisos mínimos para administración y despliegue.
- Parámetros de conexión no secretos en Parameter Store.

## Antes de desplegar

1. Confirme que la región de AWS CLI sea `us-east-1`.
2. Confirme que el presupuesto y sus alertas estén activos.
3. Revise el costo estimado de ALB, NAT Gateway, EC2 y RDS.
4. No despliegue una segunda copia de la pila.

## Validación sin crear recursos

```bash
aws cloudformation validate-template \
  --region us-east-1 \
  --template-body file://infrastructure/cloudformation/main.yml
```

Este comando solamente valida la plantilla; no crea infraestructura.

## Despliegue

```bash
aws cloudformation deploy \
  --region us-east-1 \
  --stack-name saludos-entregable-prod \
  --template-file infrastructure/cloudformation/main.yml \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides ProjectName=saludos Environment=prod \
  --tags Project=saludos Environment=prod Course=DevOps
```

Cuando termine, consulte los valores que deben configurarse en GitHub:

```bash
aws cloudformation describe-stacks \
  --region us-east-1 \
  --stack-name saludos-entregable-prod \
  --query 'Stacks[0].Outputs'
```

Configure las variables del repositorio `AWS_REGION`, `BACKEND_INSTANCE_ID`,
`BACKEND_PRIVATE_DNS`, `FRONTEND_INSTANCE_IDS` y `APP_URL` con esos valores.

## Registro del runner

Obtenga un token temporal en GitHub, en **Settings > Actions > Runners > New
self-hosted runner**. Después abra una sesión de Systems Manager en la EC2 cuyo
ID aparece como `RunnerInstanceId` y ejecute:

```bash
cd /opt/actions-runner
sudo -u github-runner ./config.sh \
  --url https://github.com/Algecas/cicd-aws-entregable1 \
  --token TOKEN_TEMPORAL \
  --name aws-frontend-runner \
  --labels aws \
  --unattended \
  --replace
sudo ./svc.sh install github-runner
sudo ./svc.sh start
```

El token es temporal y no debe copiarse al repositorio.

## Eliminación al terminar

```bash
aws cloudformation delete-stack \
  --region us-east-1 \
  --stack-name saludos-entregable-prod
```

Compruebe que la pila quede en `DELETE_COMPLETE`. La base de datos del
laboratorio se elimina junto con la pila para evitar costos residuales.
