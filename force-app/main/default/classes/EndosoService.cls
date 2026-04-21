public class EndosoService {

    public static void aplicarEndosos(List<Endoso__c> endosos) {
        for (Endoso__c endoso : endosos) {
            switch on endoso.Tipo_de_endoso__c {
                when 'Financiero', 'Modificación' {
                    aplicarEndosoFinanciero(endoso);
                }
                when 'Cancelación' {
                    aplicarCancelacion(endoso);
                }
                when 'Renovación' {
                    aplicarRenovacion(endoso);
                }
            }
        }
    }

    private static void aplicarEndosoFinanciero(Endoso__c endoso) {

        Pago__c planActual = [
            SELECT Id, Name, MontoTotal__c, Modalidad_de_pago__c,
                   Fecha_de_inicio__c, Numero_de_pagos__c, Version__c,
                   Poliza__c
            FROM Pago__c
            WHERE Id = :endoso.Plan_de_pago__c
        ];

        List<Pago_Parcial__c> todosLosParciales = [
            SELECT Id, Estado__c, Monto_pagado__c, Pago_confirmado__c,
                   Cancelado_por_Endoso__c
            FROM Pago_Parcial__c
            WHERE Pago_relacionado__c = :planActual.Id
            AND Cancelado_por_Endoso__c = false
        ];

        Decimal montoPagadoAcumulado = 0;
        List<Pago_Parcial__c> pendientes = new List<Pago_Parcial__c>();

        for (Pago_Parcial__c pp : todosLosParciales) {
            if (pp.Pago_confirmado__c == true) {
                montoPagadoAcumulado += pp.Monto_pagado__c != null ? pp.Monto_pagado__c : 0;
            } else {
                pendientes.add(pp);
            }
        }

        // Cancelar pagos parciales pendientes del plan actual
        for (Pago_Parcial__c pp : pendientes) {
            pp.Cancelado_por_Endoso__c = true;
            pp.Estado__c               = 'Cancelado';
            pp.Endoso__c               = endoso.Id;
        }
        if (!pendientes.isEmpty()) update pendientes;

        // Cerrar el plan actual
        update new Pago__c(
            Id                 = planActual.Id,
            Estatus_de_pago__c = 'Cerrado'
        );

        // Calcular saldo pendiente sobre la nueva prima
        Decimal nuevaPrima = endoso.Nueva_Prima__c != null
                              ? endoso.Nueva_Prima__c
                              : planActual.MontoTotal__c;
        Decimal saldoPendiente = nuevaPrima - montoPagadoAcumulado;

        String modalidad = endoso.Nueva_Modalidad__c != null
                            ? endoso.Nueva_Modalidad__c
                            : planActual.Modalidad_de_pago__c;

        Integer pagosRestantes = pendientes.size();

        // Nombre base sin sufijo de versión previo + nueva versión
        String nombreBase    = planActual.Name.replaceAll(' v\\d+$', '');
        Integer nuevaVersion = (planActual.Version__c != null ? Integer.valueOf(planActual.Version__c) : 1) + 1;

        Pago__c nuevoPlan = new Pago__c(
            Name                 = nombreBase + ' v' + nuevaVersion,
            Poliza__c            = planActual.Poliza__c,
            MontoTotal__c        = saldoPendiente,
            Modalidad_de_pago__c = modalidad,
            Fecha_de_inicio__c   = endoso.Fecha_Efectiva__c,
            Numero_de_pagos__c   = pagosRestantes,
            Estatus_de_pago__c   = 'Activo',
            Es_Plan_Endoso__c    = true,
            Endoso__c            = endoso.Id,
            Plan_Anterior__c     = planActual.Id,
            Version__c           = nuevaVersion
        );
        insert nuevoPlan;

        update new Endoso__c(
            Id        = endoso.Id,
            Estado__c = 'Aplicado'
        );
    }

    private static void aplicarCancelacion(Endoso__c endoso) {

        List<Pago_Parcial__c> pendientes = [
            SELECT Id, Estado__c, Cancelado_por_Endoso__c
            FROM Pago_Parcial__c
            WHERE Pago_relacionado__c = :endoso.Plan_de_pago__c
            AND Pago_confirmado__c = false
            AND Cancelado_por_Endoso__c = false
        ];

        for (Pago_Parcial__c pp : pendientes) {
            pp.Estado__c               = 'Cancelado';
            pp.Cancelado_por_Endoso__c = true;
            pp.Endoso__c               = endoso.Id;
        }
        if (!pendientes.isEmpty()) update pendientes;

        update new Pago__c(
            Id                 = endoso.Plan_de_pago__c,
            Estatus_de_pago__c = 'Cancelado'
        );

        update new Endoso__c(
            Id        = endoso.Id,
            Estado__c = 'Aplicado'
        );
    }

    private static void aplicarRenovacion(Endoso__c endoso) {

        Pago__c planActual = [
            SELECT Id, Name, MontoTotal__c, Modalidad_de_pago__c,
                   Numero_de_pagos__c, Version__c, Poliza__c
            FROM Pago__c
            WHERE Id = :endoso.Plan_de_pago__c
        ];

        update new Pago__c(
            Id                 = planActual.Id,
            Estatus_de_pago__c = 'Cerrado'
        );

        Decimal nuevaPrima = endoso.Nueva_Prima__c != null
                              ? endoso.Nueva_Prima__c
                              : planActual.MontoTotal__c;

        String modalidad = endoso.Nueva_Modalidad__c != null
                            ? endoso.Nueva_Modalidad__c
                            : planActual.Modalidad_de_pago__c;

        // En renovación siempre se genera el período completo
        // por eso NO se marca Es_Plan_Endoso__c = true
        Integer numeroPagos = PagoTriggerHandler.obtenerNumeroPagos(modalidad);

        // Nombre base sin sufijo de versión previo + nueva versión
        String nombreBase    = planActual.Name.replaceAll(' v\\d+$', '');
        Integer nuevaVersion = (planActual.Version__c != null ? Integer.valueOf(planActual.Version__c) : 1) + 1;

        Pago__c nuevoPlan = new Pago__c(
            Name                 = nombreBase + ' v' + nuevaVersion,
            Poliza__c            = planActual.Poliza__c,
            MontoTotal__c        = nuevaPrima,
            Modalidad_de_pago__c = modalidad,
            Fecha_de_inicio__c   = endoso.Fecha_Efectiva__c,
            Numero_de_pagos__c   = numeroPagos,
            Estatus_de_pago__c   = 'Activo',
            Endoso__c            = endoso.Id,
            Plan_Anterior__c     = planActual.Id,
            Version__c           = nuevaVersion
        );
        insert nuevoPlan;

        update new Endoso__c(
            Id        = endoso.Id,
            Estado__c = 'Aplicado'
        );
    }
}