public class PagoTriggerHandler {

    public static void generarPagosParciales(List<Pago__c> pagos) {
        List<Pago_Parcial__c> pagosParciales  = new List<Pago_Parcial__c>();
        List<Pago__c> pagosParaActualizar     = new List<Pago__c>();

        for (Pago__c pago : pagos) {

            if (pago.Fecha_de_inicio__c == null
                || pago.MontoTotal__c == null
                || pago.Modalidad_de_pago__c == null) {
                continue;
            }

            // Si viene de un endoso financiero, respeta los pagos restantes
            // Si es un plan nuevo normal, lo deriva de la modalidad
            Integer numeroPagos = (pago.Es_Plan_Endoso__c == true && pago.Numero_de_pagos__c != null)
                                    ? Integer.valueOf(pago.Numero_de_pagos__c)
                                    : obtenerNumeroPagos(pago.Modalidad_de_pago__c);

            Decimal montoParcial = pago.MontoTotal__c / numeroPagos;
            Date fechaBase       = pago.Fecha_de_inicio__c;

            for (Integer i = 1; i <= numeroPagos; i++) {
                Date fechaPago = calcularFecha(fechaBase, pago.Modalidad_de_pago__c, i);

                pagosParciales.add(new Pago_Parcial__c(
                    Pago_relacionado__c         = pago.Id,
                    Numero_de_pago__c           = i,
                    Monto_programado__c         = montoParcial.setScale(2),
                    Fecha_de_pago_programada__c = fechaPago
                ));
            }

            Date fechaFin = calcularFecha(fechaBase, pago.Modalidad_de_pago__c, numeroPagos);

            pagosParaActualizar.add(new Pago__c(
                Id                 = pago.Id,
                Fecha_de_fin__c    = fechaFin,
                Monto_por_pago__c  = montoParcial.setScale(2),
                Saldo_pendiente__c = pago.MontoTotal__c,
                Numero_de_pagos__c = numeroPagos
            ));
        }

        if (!pagosParciales.isEmpty()) insert pagosParciales;
        if (!pagosParaActualizar.isEmpty()) update pagosParaActualizar;
    }

    private static Date calcularFecha(Date fechaBase, String modalidad, Integer i) {
        switch on modalidad {
            when 'Mensual'    { return fechaBase.addMonths(i); }
            when 'Bimestral'  { return fechaBase.addMonths(i * 2); }
            when 'Trimestral' { return fechaBase.addMonths(i * 3); }
            when 'Semestral'  { return fechaBase.addMonths(i * 6); }
            when 'Anual'      { return fechaBase.addMonths(i * 12); }
            when 'Quincenal'  { return fechaBase.addDays(i * 15); }
            when else         { return fechaBase.addMonths(i); }
        }
    }

    public static Integer obtenerNumeroPagos(String modalidad) {
        switch on modalidad {
            when 'Mensual'    { return 12; }
            when 'Bimestral'  { return 6; }
            when 'Trimestral' { return 4; }
            when 'Semestral'  { return 2; }
            when 'Anual'      { return 1; }
            when 'Quincenal'  { return 24; }
            when else         { return 12; }
        }
    }
}