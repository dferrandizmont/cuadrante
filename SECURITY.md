# Avisos de seguridad

Si encuentras una vulnerabilidad, escribe a **turnly@mainshai.com**.

Incluye la versión afectada, los pasos para reproducir el problema y su posible
impacto. Comunica los detalles por correo antes de abrir una incidencia pública,
para permitir que se revise y prepare una corrección.

## No adjuntes datos reales

Una copia `.cuadrante`, una captura del calendario o del widget, o un archivo
`.ics`, CSV o `.Shifter` de verdad lleva tus turnos, tus notas y tus ausencias,
y entre ellas puede haber una baja médica u otro dato de salud. Nada de eso hace
falta para arreglar un fallo:

- Reproduce el problema con datos inventados (la app arranca con datos de
  demostración en desarrollo) y adjunta esa copia, no la tuya.
- Si necesitas mandar un archivo real, quita antes las notas, las ausencias y
  los nombres de calendario y de tipos de turno que te identifiquen. Una copia
  `.cuadrante` es JSON comprimido con gzip y se puede editar.
- En las capturas, tapa fechas, notas y códigos de turno que no sean de prueba.
- Nunca mandes claves, keystores ni archivos `.env`.

Lo mismo vale para las incidencias y las solicitudes de cambio públicas.

English version: [SECURITY.en.md](SECURITY.en.md).
