/**
 * Job programado diario: cuando un recibo lleva > 7 dias en 'Vencido' sin pago,
 * crea una Task al OwnerId del Seguro (vendedor/operacion) para escalar cobro.
 *
 * Evita duplicados con una clave idempotente: Task.Subject incluye el recibo ID,
 * de modo que si ya existe una Task abierta para ese recibo no se crea otra.
 */
public with sharing class ScheduledReciboTaskMora implements Schedulable {

    @TestVisible
    private static final Integer DIAS_MORA_MINIMO = 7;

    public void execute(SchedulableContext sc) {
        runNow();
    }

    public static Integer runNow() {
        Date limiteMora = Date.today().addDays(-DIAS_MORA_MINIMO);

        // Recibos vencidos con mora > 7 dias, sin pago registrado.
        List<Recibo_de_Cobro__c> morosos = [
            SELECT Id, Name, Plan_de_Pagos__c, Plan_de_Pagos__r.Seguro__c,
                   Plan_de_Pagos__r.Seguro__r.OwnerId,
                   Plan_de_Pagos__r.Seguro__r.Numero_poliza__c,
                   Monto_programado__c, Fecha_programada__c
            FROM Recibo_de_Cobro__c
            WHERE Estado__c = 'Vencido'
              AND Fecha_programada__c <= :limiteMora
              AND Fecha_pago__c = null
            LIMIT 5000
        ];
        if (morosos.isEmpty()) return 0;

        // Idempotencia: buscamos tasks abiertas cuyo WhatId sea alguno de los recibos.
        Set<Id> reciboIds = new Set<Id>();
        for (Recibo_de_Cobro__c r : morosos) reciboIds.add(r.Id);

        Set<Id> yaConTask = new Set<Id>();
        for (Task t : [
            SELECT WhatId FROM Task
            WHERE WhatId IN :reciboIds
              AND IsClosed = false
              AND Subject LIKE 'Cobranza mora%'
        ]) {
            yaConTask.add(t.WhatId);
        }

        List<Task> nuevas = new List<Task>();
        for (Recibo_de_Cobro__c r : morosos) {
            if (yaConTask.contains(r.Id)) continue;
            Task t = new Task();
            t.Subject  = 'Cobranza mora - ' + r.Name;
            t.WhatId   = r.Id;
            t.Priority = 'High';
            t.Status   = 'Open';
            t.ActivityDate = Date.today();
            Id ownerId = r.Plan_de_Pagos__r != null && r.Plan_de_Pagos__r.Seguro__r != null
                ? r.Plan_de_Pagos__r.Seguro__r.OwnerId
                : null;
            if (ownerId != null) t.OwnerId = ownerId;
            String poliza = r.Plan_de_Pagos__r != null && r.Plan_de_Pagos__r.Seguro__r != null
                ? r.Plan_de_Pagos__r.Seguro__r.Numero_poliza__c
                : '';
            t.Description = 'Recibo ' + r.Name +
                ' de la poliza ' + (poliza != null ? poliza : '') +
                ' sigue vencido desde ' + String.valueOf(r.Fecha_programada__c) +
                '. Monto: ' + String.valueOf(r.Monto_programado__c) + '.';
            nuevas.add(t);
        }
        if (!nuevas.isEmpty()) insert nuevas;
        return nuevas.size();
    }
}