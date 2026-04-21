/**
 * Handler: ReciboDeCobroTriggerHandler
 *
 * Responsabilidades:
 *   - Auto-numerar Numero__c dentro del plan (si viene en blanco).
 *   - Auto-avanzar Estado segun Monto_pagado vs Monto_programado.
 *   - Auto-fijar Fecha_pago cuando Estado pasa a Pagado.
 *   - Refrescar Plan_de_Pagos__c.Dias_mora__c y Seguro__c.Recibos_vencidos__c.
 */
public with sharing class ReciboDeCobroTriggerHandler {

    // =========================================================================
    // BEFORE INSERT
    // =========================================================================
    public void onBeforeInsert(List<Recibo_de_Cobro__c> nuevos) {
        // Defaults
        for (Recibo_de_Cobro__c r : nuevos) {
            if (String.isBlank(r.Estado__c)) {
                r.Estado__c = 'Pendiente';
            }
            aplicarLogicaEstadoYMonto(r);
        }

        // Auto-numerar Numero__c dentro del plan si viene vacio.
        autonumerar(nuevos);
    }

    // =========================================================================
    // BEFORE UPDATE
    // =========================================================================
    public void onBeforeUpdate(List<Recibo_de_Cobro__c> nuevos, Map<Id, Recibo_de_Cobro__c> viejos) {
        for (Recibo_de_Cobro__c r : nuevos) {
            aplicarLogicaEstadoYMonto(r);
        }
    }

    // =========================================================================
    // AFTER INSERT
    // =========================================================================
    public void onAfterInsert(List<Recibo_de_Cobro__c> nuevos) {
        Set<Id> planIds = new Set<Id>();
        Set<Id> seguroIds = new Set<Id>();
        for (Recibo_de_Cobro__c r : nuevos) {
            if (r.Plan_de_Pagos__c != null) planIds.add(r.Plan_de_Pagos__c);
        }
        refrescarAgregados(planIds);
    }

    // =========================================================================
    // AFTER UPDATE
    // =========================================================================
    public void onAfterUpdate(List<Recibo_de_Cobro__c> nuevos, Map<Id, Recibo_de_Cobro__c> viejos) {
        Set<Id> planIds = new Set<Id>();
        for (Recibo_de_Cobro__c r : nuevos) {
            Recibo_de_Cobro__c viejo = viejos.get(r.Id);
            // Solo refrescar si cambio algo que afecte agregados
            if (r.Estado__c != viejo.Estado__c
                || r.Fecha_pago__c != viejo.Fecha_pago__c
                || r.Fecha_programada__c != viejo.Fecha_programada__c
                || r.Monto_pagado__c != viejo.Monto_pagado__c
                || r.Plan_de_Pagos__c != viejo.Plan_de_Pagos__c) {
                if (r.Plan_de_Pagos__c != null) planIds.add(r.Plan_de_Pagos__c);
                if (viejo.Plan_de_Pagos__c != null) planIds.add(viejo.Plan_de_Pagos__c);
            }
        }
        refrescarAgregados(planIds);
    }

    // =========================================================================
    // AFTER DELETE
    // =========================================================================
    public void onAfterDelete(List<Recibo_de_Cobro__c> borrados) {
        Set<Id> planIds = new Set<Id>();
        for (Recibo_de_Cobro__c r : borrados) {
            if (r.Plan_de_Pagos__c != null) planIds.add(r.Plan_de_Pagos__c);
        }
        refrescarAgregados(planIds);
    }

    // =========================================================================
    // AFTER UNDELETE
    // =========================================================================
    public void onAfterUndelete(List<Recibo_de_Cobro__c> restaurados) {
        Set<Id> planIds = new Set<Id>();
        for (Recibo_de_Cobro__c r : restaurados) {
            if (r.Plan_de_Pagos__c != null) planIds.add(r.Plan_de_Pagos__c);
        }
        refrescarAgregados(planIds);
    }

    // =========================================================================
    // PRIVATE HELPERS
    // =========================================================================

    /**
     * Logica de auto-estado segun montos:
     *   Monto_pagado >= Monto_programado  -> Pagado
     *   0 < Monto_pagado < Monto_programado -> Parcial
     *   Vencido sin pago => se deja como este; la formula Dias_mora lo refleja.
     * Tambien: si Estado=Pagado y Fecha_pago=null -> Fecha_pago = TODAY.
     */
    private void aplicarLogicaEstadoYMonto(Recibo_de_Cobro__c r) {
        // Auto-avanzar a Pagado si el monto lo indica
        if (r.Monto_pagado__c != null
            && r.Monto_programado__c != null
            && r.Estado__c != 'Cancelado'
            && r.Estado__c != 'Reembolsado') {

            if (r.Monto_pagado__c >= r.Monto_programado__c) {
                r.Estado__c = 'Pagado';
            } else if (r.Monto_pagado__c > 0) {
                r.Estado__c = 'Parcial';
            }
        }

        // Fecha_pago automatica al pagar
        if (r.Estado__c == 'Pagado' && r.Fecha_pago__c == null) {
            r.Fecha_pago__c = Date.today();
        }
    }

    /**
     * Auto-numera Numero__c secuencialmente dentro de cada plan.
     * Consulta el MAX existente por plan y asigna MAX+1+offset.
     */
    private void autonumerar(List<Recibo_de_Cobro__c> nuevos) {
        Set<Id> planIds = new Set<Id>();
        for (Recibo_de_Cobro__c r : nuevos) {
            if (r.Numero__c == null && r.Plan_de_Pagos__c != null) {
                planIds.add(r.Plan_de_Pagos__c);
            }
        }
        if (planIds.isEmpty()) return;

        Map<Id, Integer> maxPorPlan = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT Plan_de_Pagos__c planId, MAX(Numero__c) maxNum
            FROM Recibo_de_Cobro__c
            WHERE Plan_de_Pagos__c IN :planIds
            GROUP BY Plan_de_Pagos__c
        ]) {
            Id planId = (Id) ar.get('planId');
            Decimal maxNum = (Decimal) ar.get('maxNum');
            maxPorPlan.put(planId, maxNum == null ? 0 : maxNum.intValue());
        }

        Map<Id, Integer> offset = new Map<Id, Integer>();
        for (Recibo_de_Cobro__c r : nuevos) {
            if (r.Numero__c == null && r.Plan_de_Pagos__c != null) {
                Integer base = maxPorPlan.containsKey(r.Plan_de_Pagos__c)
                    ? maxPorPlan.get(r.Plan_de_Pagos__c) : 0;
                Integer off = offset.containsKey(r.Plan_de_Pagos__c)
                    ? offset.get(r.Plan_de_Pagos__c) : 0;
                off += 1;
                offset.put(r.Plan_de_Pagos__c, off);
                r.Numero__c = base + off;
            }
        }
    }

    /**
     * Refresca agregados dependientes:
     *   1. Plan_de_Pagos__c.Dias_mora__c (MAX de recibos)
     *   2. Seguro__c.Recibos_vencidos__c (count de recibos en mora por poliza)
     */
    private void refrescarAgregados(Set<Id> planIds) {
        if (planIds == null || planIds.isEmpty()) return;

        // 1. Refrescar Dias_mora por plan
        PlanDePagosTriggerHandler.recalcularDiasMora(planIds);

        // 2. Refrescar Recibos_vencidos a nivel Seguro
        Set<Id> seguroIds = new Set<Id>();
        for (Plan_de_Pagos__c p : [
            SELECT Seguro__c FROM Plan_de_Pagos__c WHERE Id IN :planIds
        ]) {
            if (p.Seguro__c != null) seguroIds.add(p.Seguro__c);
        }
        refrescarRecibosVencidos(seguroIds);
    }

    /**
     * Cuenta recibos vencidos (Fecha_programada < TODAY y no pagados/cancelados)
     * por poliza, y actualiza Seguro__c.Recibos_vencidos__c.
     */
    public static void refrescarRecibosVencidos(Set<Id> seguroIds) {
        if (seguroIds == null || seguroIds.isEmpty()) return;
        if (TriggerGuard.ejecutandose('SeguroRecibosVencidos')) return;
        TriggerGuard.marcar('SeguroRecibosVencidos');

        Map<Id, Integer> contadoPorSeguro = new Map<Id, Integer>();
        for (Id sid : seguroIds) contadoPorSeguro.put(sid, 0);

        for (AggregateResult ar : [
            SELECT Plan_de_Pagos__r.Seguro__c seguroId, COUNT(Id) cnt
            FROM Recibo_de_Cobro__c
            WHERE Plan_de_Pagos__r.Seguro__c IN :seguroIds
              AND Fecha_programada__c < :Date.today()
              AND Estado__c != 'Pagado'
              AND Estado__c != 'Cancelado'
              AND Estado__c != 'Reembolsado'
            GROUP BY Plan_de_Pagos__r.Seguro__c
        ]) {
            Id sid = (Id) ar.get('seguroId');
            Integer cnt = ((Decimal) ar.get('cnt')).intValue();
            contadoPorSeguro.put(sid, cnt);
        }

        List<Seguro__c> aActualizar = new List<Seguro__c>();
        for (Seguro__c s : [
            SELECT Id, Recibos_vencidos__c
            FROM Seguro__c
            WHERE Id IN :seguroIds
        ]) {
            Integer nuevoValor = contadoPorSeguro.containsKey(s.Id) ? contadoPorSeguro.get(s.Id) : 0;
            if (s.Recibos_vencidos__c != nuevoValor) {
                s.Recibos_vencidos__c = nuevoValor;
                aActualizar.add(s);
            }
        }

        if (!aActualizar.isEmpty()) {
            update aActualizar;
        }
    }
}