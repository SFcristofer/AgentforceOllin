/**
 * CobranzaVencidoBatch — Scheduled Batch diario.
 *
 * Responsabilidades:
 *  1. Auto-marcar como 'Vencido' los recibos con Fecha_programada__c < TODAY
 *     y Estado__c = 'Pendiente'.
 *  2. Escalamiento: si un recibo lleva > 7 días vencido y no tiene Task abierta
 *     de seguimiento, crear una Task asignada al Vendedor del seguro.
 *
 * Schedule recomendado: diario a las 06:00 CDMX.
 *   System.schedule('Cobranza Vencidos Diario', '0 0 6 * * ?', new CobranzaVencidoScheduler());
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
public with sharing class CobranzaVencidoBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Integer totalMarkedVencido  = 0;
    public Integer totalTasksCreated   = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Traemos recibos pendientes de fecha pasada + recibos ya vencidos sin escalamiento.
        return Database.getQueryLocator([
            SELECT Id, Estado__c, Fecha_programada__c, Dias_mora__c,
                   Plan_de_Pagos__c, Plan_de_Pagos__r.Seguro__c,
                   Plan_de_Pagos__r.Seguro__r.Vendedor__c,
                   Plan_de_Pagos__r.Seguro__r.Cliente__c,
                   Poliza_numero__c, Cliente_nombre__c, Monto_programado__c
            FROM Recibo_de_Cobro__c
            WHERE Estado__c IN ('Pendiente', 'Vencido')
              AND Fecha_programada__c != null
              AND Fecha_programada__c <= :Date.today()
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Recibo_de_Cobro__c> scope) {
        List<Recibo_de_Cobro__c> toUpdate = new List<Recibo_de_Cobro__c>();
        List<Task> tasksToInsert = new List<Task>();

        Date today = Date.today();

        // Buscar IDs de recibos que ya tienen Task abierta de escalamiento
        Set<Id> reciboIds = new Set<Id>();
        for (Recibo_de_Cobro__c r : scope) { reciboIds.add(r.Id); }
        Set<Id> reciboConTask = new Set<Id>();
        for (Task t : [
            SELECT WhatId FROM Task
            WHERE WhatId IN :reciboIds
              AND Subject LIKE 'Escalamiento cobranza%'
              AND IsClosed = false
        ]) {
            reciboConTask.add(t.WhatId);
        }

        for (Recibo_de_Cobro__c r : scope) {
            Integer dias = (r.Fecha_programada__c != null)
                ? r.Fecha_programada__c.daysBetween(today)
                : 0;

            // 1) Auto-marcar Vencido
            if (r.Estado__c == 'Pendiente' && dias > 0) {
                r.Estado__c = 'Vencido';
                toUpdate.add(r);
                totalMarkedVencido++;
            }

            // 2) Escalamiento si >7d vencido y no hay Task abierta aún
            if (dias > 7 && !reciboConTask.contains(r.Id)) {
                Task t = new Task();
                t.Subject = 'Escalamiento cobranza — ' + r.Poliza_numero__c + ' (' + dias + 'd mora)';
                t.Priority = 'High';
                t.Status = 'Not Started';
                t.ActivityDate = today;
                t.WhatId = r.Id;
                // OwnerId: default (running user). Vendedor__c es lookup a objeto custom,
                // no a User. TODO: mapear Vendedor -> User cuando haya bridge.
                t.Description = 'Recibo ' + r.Poliza_numero__c
                    + ' del cliente ' + r.Cliente_nombre__c
                    + ' lleva ' + dias + ' días vencido. Monto $' + r.Monto_programado__c
                    + '. Contactar para regularizar.';
                tasksToInsert.add(t);
                totalTasksCreated++;
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
        if (!tasksToInsert.isEmpty()) {
            Database.insert(tasksToInsert, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'CobranzaVencidoBatch finished. Vencidos=' + totalMarkedVencido
            + ' Tasks=' + totalTasksCreated);
    }
}