# Guía de Integración — Bot API para Chatbots de IA

## Descripción General

La Bot API permite que un chatbot de IA cotice seguros de automóvil, seleccione planes y genere enlaces de pago de forma programática. Todas las interacciones se realizan mediante llamadas HTTP a los endpoints `/bot`.

### Conceptos Clave

- **Autenticación**: Todas las solicitudes requieren el encabezado `X-API-Key` con una clave válida proporcionada por el administrador del sistema.
- **Límite de solicitudes (Rate Limit)**: Cada API Key tiene un límite configurable de solicitudes por minuto (por defecto 60). Si se excede, la API responde con código HTTP 429.
- **Moneda**: Todos los montos están en pesos mexicanos (MXN).
- **Forma de pago**: Siempre tarjeta de crédito. Las opciones de mensualidades se consultan mediante el endpoint de opciones de pago y el número de meses se selecciona al momento de completar el pago.
- **Vigencia de cotización**: Las cotizaciones expiran 24 horas después de su creación. Transcurrido ese plazo, se debe generar una nueva.

---

## Flujo Principal: De la Cotización al Pago

El proceso completo consta de 6 pasos. A continuación se describe cada uno con el endpoint correspondiente.

### Paso 1 — Identificar el Vehículo

Antes de cotizar, es necesario obtener el identificador único de la versión del vehículo (`vehicleVersionId`). Para esto se utiliza un flujo guiado de navegación por catálogo donde el usuario selecciona primero el año, luego la marca, el modelo y finalmente la versión.

Los endpoints se usan en la siguiente secuencia:

1. `GET /bot/catalog/years` — Devuelve los años disponibles, ordenados del más reciente al más antiguo.
2. `GET /bot/catalog/brands?year={año}` — Devuelve las marcas disponibles para el año seleccionado. Cada marca incluye su `id` y `name`.
3. `GET /bot/catalog/models?year={año}&brandId={idMarca}` — Devuelve los modelos disponibles para el año y marca seleccionados. Cada modelo incluye su `id` y `name`.
4. `GET /bot/catalog/versions?year={año}&modelId={idModelo}` — Devuelve las versiones disponibles. El `id` de la versión elegida es el `vehicleVersionId` que se necesita para cotizar.

> **Tip para el chatbot:** Presenta las opciones al usuario en cada paso y avanza al siguiente cuando el usuario elija una. Guarda el `vehicleVersionId` de la versión seleccionada.

---

### Paso 2 — Generar la Cotización

**Endpoint:** `POST /bot/quotation`

Con el `vehicleVersionId` obtenido en el paso anterior, se genera una cotización enviando los datos del asegurado y el tipo de cobertura.

#### Datos requeridos

| Dato | Descripción | Obligatorio |
|------|-------------|:-----------:|
| `vehicleVersionId` | Identificador de la versión del vehículo | Sí |
| `insured.name` | Nombre completo del conductor | Sí |
| `insured.phone` | Teléfono con código de país (ej. +525512345678) | Sí |
| `insured.email` | Correo electrónico | No |
| `insured.zipCode` | Código postal mexicano (5 dígitos) | Sí |
| `insured.birthDate` | Fecha de nacimiento en formato ISO 8601 (ej. 1990-03-15) | Sí |
| `insured.gender` | Género: `M` (masculino) o `F` (femenino) | Sí |
| `coverage` | Tipo de cobertura: `AMPLIA`, `LIMITADA` o `RC` | Sí |
| `insurers` | Lista de aseguradoras específicas a consultar | No |
| `timeout` | Tiempo de espera en milisegundos (por defecto 30,000) | No |

**Tipos de cobertura disponibles:**

| Clave | Nombre | Descripción |
|-------|--------|-------------|
| `AMPLIA` | Cobertura Amplia | Cobertura completa con daños propios |
| `LIMITADA` | Cobertura Limitada | Cobertura básica sin daños propios |
| `RC` | Responsabilidad Civil | Solo responsabilidad civil obligatoria |

> Para consultar dinámicamente las coberturas disponibles, usa `GET /bot/coverages`.

#### Resultado de la cotización

La API consulta todas las aseguradoras habilitadas para la API Key (o las indicadas en `insurers`) y devuelve un resultado consolidado que incluye:

- **quotationId**: Identificador único de la cotización — se usa en los pasos siguientes.
- **vehicle**: Datos del vehículo cotizado.
- **insured**: Datos del asegurado.
- **results**: Lista de respuestas por aseguradora.
- **successCount / errorCount**: Conteo de aseguradoras que respondieron exitosamente y con error.
- **expiresAt**: Fecha y hora de expiración de la cotización.

Cada aseguradora en `results` incluye:

| Campo | Descripción |
|-------|-------------|
| `insurer` | Nombre de la aseguradora (HDI, ANA, GNP, QUALITAS, CHUBB) |
| `packages` | Un paquete con el plan correspondiente a la cobertura solicitada |
| `quotationNumber` | Número de cotización asignado por la aseguradora |
| `error` | Mensaje de error si la aseguradora no pudo cotizar (el vehículo no está disponible, por ejemplo) |

El paquete dentro de `packages` contiene:

| Campo | Descripción |
|-------|-------------|
| `planId` | Identificador del plan (ej. "HDI-AMPLIA") |
| `planName` | Nombre del plan |
| `totalAmount` | Precio total anual en MXN |
| `currency` | Siempre "MXN" |
| `breakdown` | Desglose del precio (prima neta, IVA) — disponible para GNP y Chubb; para las demás aseguradoras es nulo |
| `coverages` | Lista de coberturas incluidas con suma asegurada y deducible |
| `deductibles` | Deducibles por tipo de cobertura |
| `installmentOptions` | Opciones de mensualidades disponibles para esa aseguradora |

> **Tip para el chatbot:** Presenta los resultados al usuario ordenados por precio, indicando la aseguradora, el precio anual, las coberturas principales y las opciones de pago. Si alguna aseguradora falló, simplemente omítela o menciona que no está disponible para ese vehículo.

---

### Paso 2 (Alternativa) — Cotización con Streaming

**Endpoint:** `GET /bot/quotation/:id/stream`

Para una experiencia de progreso en tiempo real, se puede usar el endpoint de streaming con Server-Sent Events (SSE). Esto permite mostrar al usuario el avance conforme cada aseguradora responde.

Se crea primero la cotización con `POST /bot/quotation` usando un timeout bajo (o 0), lo que devuelve un `quotationId` de inmediato. Luego se conecta al stream.

Opcionalmente se puede filtrar por aseguradoras enviando el parámetro `insurers` separado por comas.

El stream emite 4 tipos de eventos:

| Evento | Cuándo se emite | Información que incluye |
|--------|-----------------|------------------------|
| `progress` | Cuando se inicia la consulta a una aseguradora | Nombre de la aseguradora, progreso actual y total |
| `result` | Cuando una aseguradora responde con éxito | Plan, precio, coberturas y opciones de pago |
| `error` | Cuando una aseguradora no pudo cotizar | Nombre de la aseguradora y mensaje de error |
| `complete` | Cuando todas las aseguradoras terminaron | Conteo de éxitos y errores, ID de la cotización |

> **Nota:** El streaming requiere que el chatbot soporte conexiones SSE (Server-Sent Events). Si no es posible, el flujo síncrono del Paso 2 es suficiente.

---

### Paso 3 — Seleccionar un Plan

**Endpoint:** `POST /bot/quotation/:quotationId/select`

Una vez que el usuario elige una aseguradora, se confirma la selección enviando el nombre de la aseguradora.

**Dato requerido:**

| Dato | Descripción |
|------|-------------|
| `insurer` | Nombre de la aseguradora elegida: `HDI`, `ANA`, `GNP`, `QUALITAS` o `CHUBB` |

La respuesta confirma el plan seleccionado e incluye un campo muy importante: **`requiredFields`**.

#### Campo `requiredFields`

Este campo indica exactamente qué datos del asegurado se necesitan para emitir la póliza. Los campos requeridos varían según la aseguradora seleccionada.

Cada campo en la lista incluye:

| Propiedad | Descripción |
|-----------|-------------|
| `field` | Nombre del campo |
| `type` | Tipo de dato: `string`, `date` o `select` |
| `required` | Si es obligatorio o no |
| `description` | Descripción legible del campo |
| `options` | Solo para campos tipo `select`: lista de valores válidos con su clave y descripción |

**Campos que típicamente se solicitan:**

| Campo | Descripción |
|-------|-------------|
| `fullName` | Nombre(s) de pila, sin apellidos |
| `paternalSurname` | Apellido paterno |
| `maternalSurname` | Apellido materno |
| `rfcKey` | RFC del asegurado |
| `phone` | Teléfono con código de país |
| `email` | Correo electrónico |
| `street` | Dirección (calle y número) |
| `birthdate` | Fecha de nacimiento (formato ISO 8601) |
| `serialNumber` | Número de serie del vehículo (VIN) |
| `occupation` | Ocupación (campo tipo select con opciones) |
| `maritalStatus` | Estado civil (campo tipo select con opciones) |

> **Tip para el chatbot:** Usa `requiredFields` para determinar dinámicamente qué preguntas hacerle al usuario. Los campos con `required: false` pueden omitirse si el usuario no los proporciona. Para campos de tipo `select`, presenta las opciones disponibles.

---

### Paso 4 — Enviar Datos del Asegurado y Generar Póliza

**Endpoint:** `POST /bot/quotation/:quotationId/insured`

Una vez recopilados los datos indicados por `requiredFields`, se envían todos en una sola solicitud.

**Consideraciones importantes:**

- El campo `fullName` debe contener **solo el nombre de pila**, sin apellidos. Por ejemplo, para "Juan Pérez García", enviar `fullName: "Juan"`, `paternalSurname: "Pérez"`, `maternalSurname: "García"`.
- La API convierte automáticamente los formatos de `gender`, `personType` y `maritalStatus` al formato que cada aseguradora requiere. Se envía siempre en formato estándar.
- El campo `email` es obligatorio para ANA, GNP, Qualitas y Chubb.

**Formato de estado civil:**

Se envía siempre con una letra: `C` (Casado), `D` (Divorciado), `S` (Soltero), `U` (Unión Libre), `V` (Viudo). La API se encarga de convertirlo al formato de cada aseguradora.

#### Resultado

Si los datos son correctos, la API crea la póliza y devuelve:

| Campo | Descripción |
|-------|-------------|
| `quotationId` | ID de la cotización |
| `policyId` | ID de la póliza creada |
| `status` | Estado: `pending_payment` |
| `paymentUrl` | Enlace de pago para compartir con el cliente |
| `paymentToken` | Token del enlace de pago |
| `expiresAt` | Fecha y hora de expiración del enlace |

> **Tip para el chatbot:** Envía el `paymentUrl` al cliente (por WhatsApp, correo u otro canal). El cliente accede al enlace, selecciona los meses de pago y completa el pago con su tarjeta de crédito.

---

### Paso 5 — Compartir el Enlace de Pago

El chatbot debe enviar al usuario el `paymentUrl` obtenido en el paso anterior. Si necesita obtenerlo nuevamente (o regenerarlo), puede usar:

**Endpoint:** `GET /bot/policy/:policyId/payment-link`

La respuesta incluye:

| Campo | Descripción |
|-------|-------------|
| `policyId` | ID de la póliza |
| `paymentUrl` | Enlace de pago vigente |
| `expiresAt` | Fecha de expiración del enlace |
| `amount` | Monto total en MXN |
| `currency` | Siempre "MXN" |
| `insurer` | Aseguradora seleccionada |

---

### Paso 6 — Verificar el Estado de la Póliza

**Endpoint:** `GET /bot/policy/:policyId`

Permite consultar si el pago fue procesado y la póliza emitida.

La respuesta incluye datos de la póliza, el asegurado, el vehículo y la cobertura, además del campo de estado:

| Estado | Significado |
|--------|-------------|
| `pending` | Póliza creada, esperando pago del cliente |
| `approved` | Pago procesado, póliza emitida exitosamente |
| `refused` | Póliza rechazada por la aseguradora |

> **Tip para el chatbot:** Consulta periódicamente este endpoint para informar al usuario cuando su póliza esté aprobada o si hubo algún problema.

---

## Endpoints Auxiliares

### Listar aseguradoras disponibles

**Endpoint:** `GET /bot/insurers`

Devuelve la lista de aseguradoras habilitadas para la API Key en uso. Útil para saber qué aseguradoras se pueden filtrar al cotizar.

Las aseguradoras posibles son: HDI, ANA, GNP, QUALITAS y CHUBB. La disponibilidad depende de la configuración del socio asociado a la API Key.

---

### Listar tipos de cobertura

**Endpoint:** `GET /bot/coverages`

Devuelve los tipos de cobertura disponibles con su clave, nombre y descripción.

---

### Consultar opciones de mensualidades

**Endpoint:** `GET /bot/installment-options`

Devuelve las opciones generales de pago a meses: contado, 3, 6 y 12 meses sin intereses.

Acepta un parámetro opcional `quotationId` para obtener las opciones específicas de la aseguradora seleccionada en esa cotización, incluyendo el monto calculado por parcela:

| Parámetro | Descripción |
|-----------|-------------|
| `quotationId` | (Opcional) ID de la cotización. Si se envía, la respuesta incluye `amount` y `currency` por cada opción, calculados a partir del monto total de la cotización, y filtra las opciones según la aseguradora seleccionada |

Sin `quotationId`, devuelve solo las opciones genéricas (meses y etiqueta). Con `quotationId`, devuelve además el monto por parcela y la moneda para cada opción.

> **Nota:** Si la aseguradora seleccionada es QUALITAS, solo se devuelve la opción de pago de contado. El número de meses se selecciona en el formulario de pago al que accede el cliente mediante el enlace de pago.

> **Tip para el chatbot:** Usa este endpoint con el `quotationId` después de que el usuario seleccione una aseguradora (Paso 3) para mostrarle cuánto pagaría por mes en cada opción de mensualidades.

---

### Consultar datos completos de una cotización

**Endpoint:** `GET /bot/quotation/:id`

Devuelve los datos completos de una cotización existente, incluyendo todos los resultados por aseguradora (mismo formato que la respuesta de `POST /bot/quotation`).

---

## Endpoints de Consulta y Seguimiento (Uso Interno)

Estos endpoints son para uso interno del equipo de ventas de Ollin Protección, permitiendo consultar el estado de cotizaciones y actuar proactivamente con los leads.

### Listar cotizaciones con estado

**Endpoint:** `GET /bot/quotation/status`

Devuelve una lista paginada de cotizaciones con su estado actual, datos del cliente y del vehículo.

**Parámetros opcionales:**

| Parámetro | Descripción |
|-----------|-------------|
| `page` | Número de página (inicia en 0, por defecto 0) |
| `limit` | Elementos por página (por defecto 20, máximo 100) |
| `step` | Filtrar por etapa del proceso |
| `source` | Filtrar por origen (ej. `bot`) |

**Etapas posibles (`step`):**

| Etapa | Descripción |
|-------|-------------|
| `pending_quotes` | Cotización creada, esperando resultados |
| `quotes_received` | Resultados recibidos de las aseguradoras |
| `insurer_selected` | Aseguradora seleccionada por el usuario |
| `policy_pending` | Póliza pendiente de pago |
| `policy_approved` | Póliza aprobada y emitida |
| `policy_refused` | Póliza rechazada |

Cada cotización en la respuesta incluye: ID, etapa actual, datos del cliente (nombre, correo, teléfono, edad, género, código postal), datos del vehículo (año, marca, modelo, versión, cobertura), aseguradora seleccionada, lista de aseguradoras cotizadas, y fechas de creación y actualización.

---

### Consultar estado de una cotización específica

**Endpoint:** `GET /bot/quotation/:id/status`

Devuelve la misma información que el listado, pero para una cotización individual.

**Parámetros opcionales:**

| Parámetro | Descripción |
|-----------|-------------|
| `source` | Filtrar por origen (ej. `bot`) para restringir solo a cotizaciones creadas por el bot |

---

## Manejo de Errores

Todas las respuestas de error siguen un formato consistente que incluye: código HTTP, mensaje descriptivo, tipo de error y fecha/hora.

**Códigos de error comunes:**

| Código HTTP | Causa típica |
|-------------|-------------|
| 400 | Datos de entrada inválidos (validación fallida) |
| 401 | API Key ausente o inválida |
| 404 | Recurso no encontrado (vehículo, cotización o póliza inexistente) |
| 410 | Cotización expirada o token de pago vencido |
| 422 | Vehículo no disponible en la aseguradora |
| 429 | Límite de solicitudes excedido |
| 500 | Error interno del servidor |
| 503 | Aseguradora temporalmente no disponible |

**Errores por aseguradora:** Cuando una aseguradora no puede cotizar un vehículo, su resultado incluye un campo `error` con el mensaje. Esto no es un error de la API; las demás aseguradoras procesan normalmente.

---

## Buenas Prácticas para la Integración

1. **Consulta las aseguradoras disponibles** con `GET /bot/insurers` antes de iniciar el flujo, para informar al usuario qué opciones hay.
2. **Implementa reintentos con espera progresiva** ante errores 429 (límite de solicitudes).
3. **Almacena el `quotationId`** para poder consultar o retomar la cotización después.
4. **Usa `requiredFields`** del paso de selección para recopilar solo los datos necesarios según la aseguradora elegida.
5. **Presenta los errores de aseguradoras individualmente** — que una falle no invalida las que sí respondieron.
6. **Verifica la expiración** de la cotización (24 horas) antes de continuar con pasos posteriores. Si expiró, genera una nueva.
7. **El timeout por defecto es de 30 segundos** — suficiente para la mayoría de los casos. Algunas aseguradoras pueden tardar más; considera usar streaming si necesitas mostrar progreso.

---

## Resumen de Endpoints

| Método | Endpoint | Propósito |
|--------|----------|-----------|
| `GET` | `/bot/catalog/years` | Listar años disponibles |
| `GET` | `/bot/catalog/brands` | Listar marcas por año |
| `GET` | `/bot/catalog/models` | Listar modelos por año y marca |
| `GET` | `/bot/catalog/versions` | Listar versiones por año y modelo |
| `POST` | `/bot/quotation` | Generar cotización |
| `GET` | `/bot/quotation/:id` | Consultar cotización existente |
| `GET` | `/bot/quotation/:id/stream` | Cotización con streaming (SSE) |
| `POST` | `/bot/quotation/:id/select` | Seleccionar plan/aseguradora |
| `POST` | `/bot/quotation/:id/insured` | Enviar datos del asegurado y crear póliza |
| `GET` | `/bot/policy/:id` | Consultar estado de póliza |
| `GET` | `/bot/policy/:id/payment-link` | Obtener enlace de pago |
| `GET` | `/bot/insurers` | Listar aseguradoras disponibles |
| `GET` | `/bot/coverages` | Listar tipos de cobertura |
| `GET` | `/bot/installment-options` | Consultar opciones de mensualidades |
| `GET` | `/bot/quotation/status` | Listar cotizaciones con estado (uso interno) |
| `GET` | `/bot/quotation/:id/status` | Estado de una cotización específica (uso interno) |
