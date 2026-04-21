/**
 * Handler: PlanDePagosTriggerHandler
 *
 * Responsabilidades:
 *   - Defaults en insert (Fecha_inicio, Frecuencia).
 *   - Auto-marcar plan como Pagado cuando Saldo_pendiente llega a 0.
 *   - Recalcular Dias_mora del plan como MAX de sus recibos (Number, porque
 *     roll-ups sobre formulas tienen limitaciones).
 */
public with sharing class PlanDePagosTriggerHandler {

    public void onBeforeInsert(List<Plan_de_Pagos__c> nuevos) {
        for (Plan_de_Pagos__c p : nuevos) {
            if (p.Fecha_inicio__c == null) {
                p.Fecha_inicio__c = Date.today();
            }
            if (String.isBlank(p.Frecuencia__c)) {
                p.Frecuencia__c = 'Mensual';
            }
            if (String.isBlank(p.Estado__c)) {
                p.Estado__c = 'Activo';
            }
        }
    }

    public void onBeforeUpdate(List<Plan_de_Pagos__c> nuevos, Map<Id, Plan_de_Pagos__c> viejos) {
        for (Plan_de_Pagos__c p : nuevos) {
            // Auto-marcar Pagado cuando saldo llega a 0 (y no esta Cancelado/Pausado)
            if (p.Saldo_pendiente__c == 0
                && p.Estado__c != 'Pagado'
                && p.Estado__c != 'Cancelado'
                && p.Estado__c != 'Pausado') {
                p.Estado__c = 'Pagado';
            }
        }
    }

    public void onAfterInsert(List<Plan_de_Pagos__c> nuevos) {
        // Recalcular Dias_mora no aplica: planes nuevos no tienen recibos todavia.
    }

    public void onAfterUpdate(List<Plan_de_Pagos__c> nuevos, Map<Id, Plan_de_Pagos__c> viejos) {
        // Refrescar Dias_mora consultando recibos hijos.
        Set<Id> planIds = new Set<Id>();
        for (Plan_de_Pagos__c p : nuevos) {
            planIds.add(p.Id);
        }
        recalcularDiasMora(planIds);
    }

    /**
     * Recalcula el campo Plan_de_Pagos__c.Dias_mora__c tomando el MAX
     * de Recibo_de_Cobro__c.Dias_mora__c entre sus hijos.
     * Llamado desde ReciboDeCobroTriggerHandler tambien.
     */
    public static void recalcularDiasMora(Set<Id> planIds) {
        if (planIds == null || planIds.isEmpty()) return;

        // Evitar recursion
        if (TriggerGuard.ejecutandose('PlanDePagosDiasMora')) return;
        TriggerGuard.marcar('PlanDePagosDiasMora');

        // AggregateResult: MAX de Dias_mora por plan.
        Map<Id, Integer> maxPorPlan = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Plan_de_Pagos__c planId, MAX(Dias_mora__c) maxDias
            FROM Recibo_de_Cobro__c
            WHERE Plan_de_Pagos__c IN :planIds
            GROUP BY Plan_de_Pagos__c
        ]) {
            Id planId = (Id) ar.get('planId');
            Decimal maxDias = (Decimal) ar.get('maxDias');
            maxPorPlan.put(planId, maxDias == null ? 0 : maxDias.intValue());
        }

        List<Plan_de_Pagos__c> aActualizar = new List<Plan_de_Pagos__c>();
        for (Plan_de_Pagos__c p : [
            SELECT Id, Dias_mora__c
            FROM Plan_de_Pagos__c
            WHERE Id IN :planIds
        ]) {
            Integer nuevoValor = maxPorPlan.containsKey(p.Id) ? maxPorPlan.get(p.Id) : 0;
            if (p.Dias_mora__c != nuevoValor) {
                p.Dias_mora__c = nuevoValor;
                aActualizar.add(p);
            }
        }

        if (!aActualizar.isEmpty()) {
            update aActualizar;
        }
    }
}