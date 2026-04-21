/**
 * Tests para PlanDePagosTriggerHandler.
 * Cubre: defaults, auto-Pagado al llegar saldo a 0, recalculo de Dias_mora.
 */
@IsTest
private class PlanDePagosTriggerHandlerTest {

    @IsTest
    static void testDefaultsEnInsert() {
        Seguro__c s = TestDataFactoryGestion.crearSeguro();

        Test.startTest();
        Plan_de_Pagos__c p = new Plan_de_Pagos__c(
            Seguro__c = s.Id,
            Monto__c = 12000,
            Num_recibos__c = 12
            // No asignamos Fecha_inicio, Frecuencia ni Estado
        );
        insert p;
        Test.stopTest();

        Plan_de_Pagos__c recargado = [
            SELECT Id, Fecha_inicio__c, Frecuencia__c, Estado__c
            FROM Plan_de_Pagos__c
            WHERE Id = :p.Id
        ];
        System.assertEquals(Date.today(), recargado.Fecha_inicio__c, 'Fecha_inicio debe autollenarse');
        System.assertEquals('Mensual', recargado.Frecuencia__c, 'Frecuencia default debe ser Mensual');
        System.assertEquals('Activo', recargado.Estado__c, 'Estado default debe ser Activo');
    }

    @IsTest
    static void testAutoPagadoAlLlegarSaldoCero() {
        Seguro__c s = TestDataFactoryGestion.crearSeguro();
        Plan_de_Pagos__c p = TestDataFactoryGestion.crearPlan(s.Id, 1000, 2);
        List<Recibo_de_Cobro__c> recibos = TestDataFactoryGestion.crearRecibos(p.Id, 2, 500);

        Test.startTest();
        // Pagar todos los recibos
        for (Recibo_de_Cobro__c r : recibos) {
            r.Monto_pagado__c = 500;
            r.Estado__c = 'Pagado';
        }
        update recibos;
        Test.stopTest();

        Plan_de_Pagos__c recargado = [
            SELECT Id, Saldo_pendiente__c, Estado__c
            FROM Plan_de_Pagos__c
            WHERE Id = :p.Id
        ];
        System.assertEquals(0, recargado.Saldo_pendiente__c, 'Saldo pendiente debe ser 0');
        System.assertEquals('Pagado', recargado.Estado__c, 'Estado debe avanzar a Pagado');
    }

    @IsTest
    static void testSaldoPendienteConPagoParcial() {
        // Valida que la formula Recibo.Saldo__c considera pagos parciales
        // y que el roll-up Plan.Saldo_pendiente__c refleja el saldo real.
        Seguro__c s = TestDataFactoryGestion.crearSeguro();
        Plan_de_Pagos__c p = TestDataFactoryGestion.crearPlan(s.Id, 1000, 2);
        List<Recibo_de_Cobro__c> recibos = TestDataFactoryGestion.crearRecibos(p.Id, 2, 500);

        Test.startTest();
        // Pagar el primer recibo completo (500), el segundo parcialmente (200)
        recibos[0].Monto_pagado__c = 500;
        recibos[1].Monto_pagado__c = 200;
        update recibos;
        Test.stopTest();

        Plan_de_Pagos__c recargado = [
            SELECT Id, Saldo_pendiente__c, Total_pagado__c, Estado__c
            FROM Plan_de_Pagos__c
            WHERE Id = :p.Id
        ];
        // Primer recibo: pagado, saldo 0. Segundo: parcial, saldo 300.
        System.assertEquals(300, recargado.Saldo_pendiente__c,
            'Saldo pendiente debe considerar pago parcial (500-200=300)');
        // Total pagado incluye parciales (500 + 200 = 700)
        System.assertEquals(700, recargado.Total_pagado__c,
            'Total pagado debe incluir pagos parciales');
        System.assertEquals('Activo', recargado.Estado__c,
            'Plan aun no debe marcarse como Pagado');
    }

    @IsTest
    static void testRecalculoDiasMora() {
        Seguro__c s = TestDataFactoryGestion.crearSeguro();
        Plan_de_Pagos__c p = TestDataFactoryGestion.crearPlan(s.Id, 1000, 2);

        // Crear un recibo con fecha vencida
        Recibo_de_Cobro__c vencido = new Recibo_de_Cobro__c(
            Plan_de_Pagos__c = p.Id,
            Fecha_programada__c = Date.today().addDays(-45),
            Monto_programado__c = 500
        );

        Test.startTest();
        insert vencido;
        Test.stopTest();

        Plan_de_Pagos__c recargado = [
            SELECT Id, Dias_mora__c
            FROM Plan_de_Pagos__c
            WHERE Id = :p.Id
        ];
        System.assert(recargado.Dias_mora__c != null && recargado.Dias_mora__c >= 45,
            'Dias_mora debe reflejar la mora del recibo vencido');
    }
}