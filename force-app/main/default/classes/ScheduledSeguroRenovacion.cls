/**
 * Job programado diario: transiciona Seguro__c de 'Vigente' a 'Por renovar'
 * cuando faltan <= 60 dias para el vencimiento (Fin_del_seguro__c).
 *
 * La transicion a 'Por renovar' dispara SeguroAutomationHandler.handleAfterUpdate,
 * que crea automaticamente la Opportunity de renovacion.
 *
 * Tambien marca 'No renovada' cuando la poliza ya vencio y sigue en 'Vigente'
 * o 'Por renovar' (sin intervencion humana en >= 7 dias).
 */
public with sharing class ScheduledSeguroRenovacion implements Schedulable {

    @TestVisible
    private static final Integer DIAS_AVISO_RENOVACION = 60;
    @TestVisible
    private static final Integer DIAS_GRACIA_VENCIDA   = 7;

    public void execute(SchedulableContext sc) {
        runNow();
    }

    public static Map<String, Integer> runNow() {
        Date hoy       = Date.today();
        Date limite60  = hoy.addDays(DIAS_AVISO_RENOVACION);
        Date limite7   = hoy.addDays(-DIAS_GRACIA_VENCIDA);

        // 1. Vigente + faltan <= 60 dias -> Por renovar
        List<Seguro__c> aPorRenovar = [
            SELECT Id, Estatus__c, Fin_del_seguro__c
            FROM Seguro__c
            WHERE Estatus__c = 'Vigente'
              AND Fin_del_seguro__c != null
              AND Fin_del_seguro__c <= :limite60
              AND Fin_del_seguro__c >= :hoy
            LIMIT 10000
        ];
        for (Seguro__c s : aPorRenovar) s.Estatus__c = 'Por renovar';
        if (!aPorRenovar.isEmpty()) update aPorRenovar;

        // 2. Fin < hoy - 7d y aun en 'Vigente' o 'Por renovar' -> No renovada
        List<Seguro__c> aNoRenovada = [
            SELECT Id, Estatus__c
            FROM Seguro__c
            WHERE Estatus__c IN ('Vigente', 'Por renovar')
              AND Fin_del_seguro__c != null
              AND Fin_del_seguro__c < :limite7
            LIMIT 10000
        ];
        for (Seguro__c s : aNoRenovada) s.Estatus__c = 'No renovada';
        if (!aNoRenovada.isEmpty()) update aNoRenovada;

        Map<String, Integer> result = new Map<String, Integer>{
            'por_renovar' => aPorRenovar.size(),
            'no_renovada' => aNoRenovada.size()
        };
        return result;
    }
}