/**
 * WebhookDomiciliacion — Apex REST endpoint para recibir confirmaciones de pasarela
 * de pagos (Stripe, Conekta, OpenPay, etc.) y marcar Recibo_de_Cobro__c como pagado.
 *
 * URL: /services/apexrest/v1/domiciliacion
 *
 * Payload esperado (POST application/json):
 * {
 *   "recibo_id"         : "a0X...",
 *   "monto_pagado"      : 1234.56,
 *   "metodo"            : "Tarjeta",
 *   "referencia"        : "ch_xxxxxxxxxxxx",
 *   "fecha_pago"        : "2026-04-19",
 *   "estatus_gateway"   : "succeeded"
 * }
 *
 * Responses:
 *   200 — { "ok": true, "recibo": "RC-00123" }
 *   400 — { "ok": false, "error": "..." }
 *   404 — { "ok": false, "error": "Recibo no encontrado" }
 *
 * Seguridad: este endpoint asume que la pasarela firma el request con HMAC.
 * La validación HMAC es un TODO hasta que se elija pasarela. Por ahora se confía
 * en la URL secreta + IP allowlist a nivel Connected App / Site Guest profile.
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
@RestResource(urlMapping='/v1/domiciliacion')
global with sharing class WebhookDomiciliacion {

    @HttpPost
    global static Response handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            String body = req.requestBody != null ? req.requestBody.toString() : null;
            if (String.isBlank(body)) {
                res.statusCode = 400;
                return new Response(false, 'Empty body', null);
            }
            Payload p = (Payload) JSON.deserialize(body, Payload.class);
            if (p == null || String.isBlank(p.recibo_id)) {
                res.statusCode = 400;
                return new Response(false, 'recibo_id requerido', null);
            }

            List<Recibo_de_Cobro__c> matches = [
                SELECT Id, Numero__c, Estado__c, Monto_pagado__c, Metodo_pago__c,
                       Referencia_pago__c, Fecha_pago__c
                FROM Recibo_de_Cobro__c
                WHERE Id = :p.recibo_id
                LIMIT 1
            ];
            if (matches.isEmpty()) {
                res.statusCode = 404;
                return new Response(false, 'Recibo no encontrado', null);
            }

            Recibo_de_Cobro__c r = matches[0];
            // Idempotencia: si ya esta Pagado y referencia coincide, devolvemos exito sin tocar
            if (r.Estado__c == 'Pagado' && p.referencia == r.Referencia_pago__c) {
                res.statusCode = 200;
                return new Response(true, null, String.valueOf(r.Numero__c));
            }

            String estatusGw = (p.estatus_gateway != null) ? p.estatus_gateway.toLowerCase() : '';
            if (estatusGw == 'succeeded' || estatusGw == 'paid' || estatusGw == 'completed') {
                r.Estado__c = 'Pagado';
                r.Monto_pagado__c = p.monto_pagado;
                r.Metodo_pago__c = p.metodo;
                r.Referencia_pago__c = p.referencia;
                if (String.isNotBlank(p.fecha_pago)) {
                    r.Fecha_pago__c = Date.valueOf(p.fecha_pago);
                } else {
                    r.Fecha_pago__c = Date.today();
                }
            } else if (estatusGw == 'failed' || estatusGw == 'declined') {
                // Mantenemos estado actual; quizá creemos Task de seguimiento
                // (por ahora solo log)
                System.debug(LoggingLevel.WARN,
                    'Webhook domiciliación: pago fallido para recibo ' + r.Id);
                res.statusCode = 200;
                return new Response(true, 'Pago fallido registrado', String.valueOf(r.Numero__c));
            }

            update r;
            res.statusCode = 200;
            return new Response(true, null, String.valueOf(r.Numero__c));

        } catch (JSONException je) {
            res.statusCode = 400;
            return new Response(false, 'JSON inválido: ' + je.getMessage(), null);
        } catch (Exception e) {
            res.statusCode = 500;
            return new Response(false, e.getMessage(), null);
        }
    }

    global class Payload {
        public String recibo_id;
        public Decimal monto_pagado;
        public String metodo;
        public String referencia;
        public String fecha_pago;
        public String estatus_gateway;
    }

    global class Response {
        public Boolean ok;
        public String error;
        public String recibo;
        public Response(Boolean ok, String error, String recibo) {
            this.ok = ok; this.error = error; this.recibo = recibo;
        }
    }
}