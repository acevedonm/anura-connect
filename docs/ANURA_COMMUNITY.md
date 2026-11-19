# Anura Connect sobre Community

Seguimiento: [AC-017](https://trello.com/c/tMFYaiKO).

El Dockerfile construye Community por defecto (`CHATWOOT_EDITION=ce`): elimina
`enterprise/` y `spec/enterprise/` de la imagen antes de cargar Rails y compilar
assets, y establece `CW_EDITION=ce`. El código Enterprise permanece intacto en
Git. No se modifican sus controles, licencias ni comunicaciones con Chatwoot.
`DISABLE_ENTERPRISE` por sí solo no sustituye esta exclusión física.

Los valores base de instalación conservan los originales de Chatwoot.
`bundle exec rails anura:branding` aplica explícitamente Anura Connect y sus logos
solo si no existe `enterprise/`. Conserva el resto de configuraciones y elimina
únicamente el aviso de restauración de configuración que una imagen EE anterior
pudo dejar en Redis. No borra datos de clientes ni cambia planes o flags de cuentas.
Los colores, iconos y assets de Anura del fork se conservan.

## Validación en dev

1. Respaldar PostgreSQL y registrar las versiones y configuraciones actuales.
   Revisar si se utilizan funciones Enterprise antes de cambiar de edición:
   esas funciones no estarán disponibles en Community, aunque sus datos persistan.
2. Construir con `docker build -f docker/Dockerfile -t anura-connect:ce .`.
   Verificar `docker run --rm --entrypoint sh anura-connect:ce -c
   'test "$CW_EDITION" = ce && test ! -d /app/enterprise'`.
3. Usar la misma imagen en web y Sidekiq. Planificar una ventana para detener los
   procesos EE anteriores; revisar y drenar los trabajos EE pendientes antes de
   sustituir workers. No purgar colas ni eliminar datos como parte de este cambio.
4. Ejecutar `bundle exec rails db:chatwoot_prepare` y luego
   `bundle exec rails anura:branding` en el entorno Community. El predeploy actual
   de Railway combina ambas tareas, pero puede coincidir con workers EE antiguos:
   volver a aplicar branding cuando ya no queden procesos EE.
5. Comprobar login, dashboard, logos, temas claro/oscuro, widget, envío y recepción
   de mensajes y trabajos Sidekiq. En Super Admin comprobar nombre y ausencia del
   aviso residual. Ejecutar branding otra vez y confirmar que no cambia otros ajustes.
6. Aprobar estos resultados antes de repetir el procedimiento en producción.

El checkout local conserva `enterprise/`; por eso la tarea lo rechaza incluso
con `DISABLE_ENTERPRISE=true`. Validar el branding en la imagen Community, sin
montar el checkout completo encima de `/app`.

## Compatibilidad Enterprise y rollback

Un build EE requiere `--build-arg CHATWOOT_EDITION=ee`; el workflow de publicación
EE lo pasa explícitamente. Conserva Enterprise y sus controles y rechaza la tarea
Anura. Para una instalación EE, quitar `anura:branding` del predeploy y usar la
configuración de branding correspondiente a su licencia. El branding visual del
fork sigue presente en los archivos compartidos; esta opción no es un rebranding
Enterprise licenciado automático.

Para rollback, coordinar web y workers con la imagen anterior y restaurar las
configuraciones previas de nombre/logos según el respaldo. No ejecutar la tarea
Anura sobre EE. Este PR no introduce migraciones ni elimina datos Enterprise;
una imagen EE restaurada volverá a aplicar sus controles habituales.
