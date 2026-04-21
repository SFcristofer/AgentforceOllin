public class PagoParcialTriggerHandler {

    // -------------------------------------------------------
    // BEFORE UPDATE: Sincroniza Estado__c con el checkbox
    // -------------------------------------------------------
    public static void actualizarEstado(List<Pago_Parcial__c> newList, Map<Id, Pago_Parcial__c> oldMap) {

        for (Pago_Parcial__c pp : newList) {
            Pago_Parcial__c old = oldMap.get(pp.Id);

            // Checkbox cambió a TRUE → evaluar monto para definir estado
            if (pp.Pago_confirmado__c == true && old.Pago_confirmado__c == false) {

                Decimal montoPagado     = pp.Monto_pagado__c != null ? pp.Monto_pagado__c : 0;
                Decimal montoProgramado = pp.Monto_programado__c != null ? pp.Monto_programado__c : 0;

                if (montoPagado >= montoProgramado) {
                    pp.Estado__c = 'Pagado';
                } else {
                    pp.Estado__c = 'Parcial';
                }

                pp.Fecha_de_pago__c = Date.today();
            }

            // Checkbox cambió a FALSE → revertir
            if (pp.Pago_confirmado__c == false && old.Pago_confirmado__c == true) {
                pp.Estado__c        = 'Pendiente';
                pp.Fecha_de_pago__c = null;
                pp.Monto_pagado__c  = null;
            }
        }
    }

    // -------------------------------------------------------
    // AFTER INSERT/UPDATE/DELETE/UNDELETE: Recalcula saldo
    // El saldo considera Monto_pagado__c real, no el programado
    // -------------------------------------------------------
    public static void recalcularSaldo(List<Pago_Parcial__c> parciales) {

        Set<Id> pagoIds = new Set<Id>();
        for (Pago_Parcial__c pp : parciales) {
            if (pp.Pago_relacionado__c != null) {
                pagoIds.add(pp.Pago_relacionado__c);
            }
        }

        if (pagoIds.isEmpty()) return;

        Map<Id, Pago__c> pagosMap = new Map<Id, Pago__c>([
            SELECT Id, MontoTotal__c
            FROM Pago__c
            WHERE Id IN :pagoIds
        ]);

        Map<Id, Decimal> montoPagadoPorPadre = new Map<Id, Decimal>();
        for (Id pid : pagoIds) {
            montoPagadoPorPadre.put(pid, 0);
        }

        // Sumamos Monto_pagado__c real de los confirmados
        List<Pago_Parcial__c> parcialesConfirmados = [
            SELECT Id, Pago_relacionado__c, Monto_pagado__c
            FROM Pago_Parcial__c
            WHERE Pago_relacionado__c IN :pagoIds
            AND Pago_confirmado__c = true
        ];

        for (Pago_Parcial__c pp : parcialesConfirmados) {
            Decimal montoActual = montoPagadoPorPadre.get(pp.Pago_relacionado__c);
            montoPagadoPorPadre.put(
                pp.Pago_relacionado__c,
                montoActual + (pp.Monto_pagado__c != null ? pp.Monto_pagado__c : 0)
            );
        }

        List<Pago__c> pagosParaActualizar = new List<Pago__c>();

        for (Id pid : pagoIds) {
            Pago__c padre       = pagosMap.get(pid);
            Decimal montoTotal  = padre.montoTotal__c != null ? padre.MontoTotal__c : 0;
            Decimal montoPagado = montoPagadoPorPadre.get(pid);
            Decimal saldo       = montoTotal - montoPagado;

            pagosParaActualizar.add(new Pago__c(
                Id                 = pid,
                Saldo_pendiente__c = saldo.setScale(2)
            ));
        }

        if (!pagosParaActualizar.isEmpty()) {
            update pagosParaActualizar;
        }
    }
}