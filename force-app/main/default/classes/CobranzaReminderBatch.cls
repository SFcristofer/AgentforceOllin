/**
 * CobranzaReminderBatch — Scheduled Batch diario.
 *
 * Envía recordatorios a recibos programados para:
 *  - +3 días (recordatorio anticipado)
 *  - HOY (día de cobro)
 *
 * Canales: Email (inmediato vía Messaging.SingleEmailMessage) + WhatsApp (stub vía
 * CobranzaMessaging.sendWhatsApp — Digital Engagement cableado en fase siguiente).
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
public with sharing class CobranzaReminderBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Integer totalRecordatorios3d = 0;
    public Integer totalRecordatoriosDia = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Date d3 = Date.today().addDays(3);
        Date dHoy = Date.today();
        return Database.getQueryLocator([
            SELECT Id, Estado__c, Fecha_programada__c,
                   Plan_de_Pagos__r.Seguro__r.Cliente__c,
                   Poliza_numero__c, Cliente_nombre__c, Monto_programado__c
            FROM Recibo_de_Cobro__c
            WHERE Estado__c = 'Pendiente'
              AND (Fecha_programada__c = :d3 OR Fecha_programada__c = :dHoy)
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Recibo_de_Cobro__c> scope) {
        // Cache de Account por Id para minimizar queries
        Set<Id> cliIds = new Set<Id>();
        for (Recibo_de_Cobro__c r : scope) {
            if (r.Plan_de_Pagos__r != null && r.Plan_de_Pagos__r.Seguro__r != null) {
                cliIds.add(r.Plan_de_Pagos__r.Seguro__r.Cliente__c);
            }
        }
        Map<Id, Account> cliMap = new Map<Id, Account>(
            [SELECT Id, PersonEmail, PersonMobilePhone FROM Account WHERE Id IN :cliIds]
        );

        for (Recibo_de_Cobro__c r : scope) {
            Id cliId = (r.Plan_de_Pagos__r != null && r.Plan_de_Pagos__r.Seguro__r != null)
                ? r.Plan_de_Pagos__r.Seguro__r.Cliente__c
                : null;
            Account cli = cliId != null ? cliMap.get(cliId) : null;
            if (cli == null) continue;

            Boolean esHoy = r.Fecha_programada__c == Date.today();
            String etiqueta = esHoy ? 'hoy' : 'en 3 días';
            String subject = esHoy
                ? 'Hoy es el día de tu pago — Póliza ' + r.Poliza_numero__c
                : 'Recordatorio: tu pago de seguro vence en 3 días';
            String monto = (r.Monto_programado__c != null) ? String.valueOf(r.Monto_programado__c) : '';
            String htmlBody =
                '<p>Hola ' + r.Cliente_nombre__c + ',</p>'
                + '<p>Te recordamos que el pago de tu póliza '
                + '<strong>' + r.Poliza_numero__c + '</strong> por '
                + '<strong>$' + monto + '</strong> vence ' + etiqueta + ' ('
                + String.valueOf(r.Fecha_programada__c) + ').</p>'
                + '<p>Si ya lo pagaste, ignora este mensaje. Cualquier duda contáctanos.</p>'
                + '<p>— Ollin Protección</p>';

            CobranzaMessaging.sendEmail(cli.Id, cli.PersonEmail, subject, htmlBody);
            CobranzaMessaging.sendWhatsApp(cli.PersonMobilePhone,
                'Hola ' + r.Cliente_nombre__c + ', tu pago de ' + r.Poliza_numero__c
                + ' por $' + monto + ' vence ' + etiqueta + '.');

            if (esHoy) totalRecordatoriosDia++; else totalRecordatorios3d++;
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'CobranzaReminderBatch finished. 3d=' + totalRecordatorios3d
            + ' Hoy=' + totalRecordatoriosDia);
    }
}