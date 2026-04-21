/**
 * Job programado diario: marca los Recibo_de_Cobro__c cuya Fecha_programada__c
 * ya paso y siguen en 'Pendiente' como 'Vencido'.
 * Usar un cron nocturno (ej. 0 0 3 * * ?) para correrlo tras medianoche.
 */
public with sharing class ScheduledReciboVencido implements Schedulable {

    public void execute(SchedulableContext sc) {
        runNow();
    }

    /**
     * Logica separada para poder invocarla desde tests o ejecucion ad-hoc.
     * Retorna cuantos recibos actualizo (util para logs).
     */
    public static Integer runNow() {
        List<Recibo_de_Cobro__c> paraActualizar = new List<Recibo_de_Cobro__c>();
        for (Recibo_de_Cobro__c r : [
            SELECT Id, Estado__c, Fecha_programada__c
            FROM Recibo_de_Cobro__c
            WHERE Estado__c = 'Pendiente'
              AND Fecha_programada__c < :Date.today()
            LIMIT 10000
        ]) {
            r.Estado__c = 'Vencido';
            paraActualizar.add(r);
        }
        if (!paraActualizar.isEmpty()) {
            update paraActualizar;
        }
        return paraActualizar.size();
    }
}