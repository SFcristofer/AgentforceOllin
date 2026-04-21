/**
 * Tests para ReciboDeCobroTriggerHandler.
 * Cubre: auto-numeracion, auto-estado por monto, auto-fecha_pago,
 * roll-up de recibos vencidos a nivel Seguro.
 */
@IsTest
private class ReciboDeCobroTriggerHandlerTest {

    @IsTest
    static void testAutoNumeracion() {
        Seguro__c s = TestDataFactoryGestion.crearSeguro();
        Plan_de_Pagos__c p = TestDataFactoryGestion.crearPlan(s.Id, 1200, 3);

        Test.startTest();
        List<Recibo_de_Cobro__c> recibos = TestDataFactoryGestion.crearRecibos(p.Id, 3, 400);
        Test.stopTest();

        List<Recibo_de_Cobro__c> cargados = [
            SELECT Id, Numero__c FROM Recibo_de_Cobro__c
            WHERE Plan_de_Pagos__c = :p.Id
            ORDER BY Numero__c ASC
        ];
        System.assertEquals(3, cargados.size(), 'Deben existir 3 recibos');
        System.assertEquals(1, cargados[0].Numero__c, 'Primer recibo con Numero=1');
        System.assertEquals(2, cargados[1].Numero__c, 'Segundo recibo con Numero=2');
        System.assertEquals(3, cargados[2].Numero__c, 'Tercer recibo con Numero=3');
    }

    @IsTest
    static void testAutoEstadoYFechaPagoAlPagar() {
        Seguro__c s = TestDataFactoryGestion.crearSeguro();
        Plan_de_Pagos__c p = TestDataFactoryGestion.crearPlan(s.Id, 500, 1);
        List<Recibo_de_Cobro__c> recibos = TestDataFactoryGestion.crearRecibos(p.Id, 1, 500);

        Test.startTest();
        Recibo_de_Cobro__c r = recibos[0];
        r.Monto_pagado__c = 500;
        // No asignamos Estado ni Fecha_pago — deben autollenarse
        update r;
        Test.stopTest();

        Recibo_de_Cobro__c recargado = [
            SELECT Estado__c, Fecha_pago__c FROM Recibo_de_Cobro__c WHERE Id = :r.Id
        ];
        System.assertEquals('Pagado', recargado.Estado__c, 'Estado debe avanzar a Pagado');
        System.assertEquals(Date.today(), recargado.Fecha_pago__c, 'Fecha_pago debe ser hoy');
    }

    @IsTest
    static void testEstadoParcialSiMontoPagadoEsMenor() {
        Seguro__c s = TestDataFactoryGestion.crearSeguro();
        Plan_de_Pagos__c p = TestDataFactoryGestion.crearPlan(s.Id, 500, 1);
        List<Recibo_de_Cobro__c> recibos = TestDataFactoryGestion.crearRecibos(p.Id, 1, 500);

        Test.startTest();
        Recibo_de_Cobro__c r = recibos[0];
        r.Monto_pagado__c = 200; // Pago parcial
        update r;
        Test.stopTest();

        Recibo_de_Cobro__c recargado = [
            SELECT Estado__c FROM Recibo_de_Cobro__c WHERE Id = :r.Id
        ];
        System.assertEquals('Parcial', recargado.Estado__c, 'Estado debe ser Parcial');
    }

    @IsTest
    static void testRollUpRecibosVencidos() {
        Seguro__c s = TestDataFactoryGestion.crearSeguro();
        Plan_de_Pagos__c p = TestDataFactoryGestion.crearPlan(s.Id, 1500, 3);

        // 2 vencidos, 1 al corriente
        List<Recibo_de_Cobro__c> recibos = new List<Recibo_de_Cobro__c>{
            new Recibo_de_Cobro__c(
                Plan_de_Pagos__c = p.Id,
                Fecha_programada__c = Date.today().addDays(-20),
                Monto_programado__c = 500),
            new Recibo_de_Cobro__c(
                Plan_de_Pagos__c = p.Id,
                Fecha_programada__c = Date.today().addDays(-10),
                Monto_programado__c = 500),
            new Recibo_de_Cobro__c(
                Plan_de_Pagos__c = p.Id,
                Fecha_programada__c = Date.today().addDays(30),
                Monto_programado__c = 500)
        };

        Test.startTest();
        insert recibos;
        Test.stopTest();

        Seguro__c recargado = [
            SELECT Recibos_vencidos__c FROM Seguro__c WHERE Id = :s.Id
        ];
        System.assertEquals(2, recargado.Recibos_vencidos__c,
            'Deben registrarse 2 recibos vencidos a nivel Seguro');
    }
}