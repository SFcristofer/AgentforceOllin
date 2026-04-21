@IsTest
private class SICASMigracionUtilTest {

    /**
     * Seguro migrado + Vigente + Mensual con Inicio hace 5 meses
     * debe producir 1 plan y recibos solo para los futuros (aprox 7).
     */
    @IsTest
    static void generaRecibosSoloFuturos() {
        Account a = new Account(Name = 'Test Cliente', RFC__c = 'XAXX010101000');
        insert a;

        Date inicio = Date.today().addMonths(-5);

        Seguro__c s = new Seguro__c(
            Cliente__c = a.Id,
            Prima_neta__c = 12000,
            Frecuencia_de_pago__c = 'Mensual',
            Estatus__c = 'Vigente',
            Inicio_del_seguro__c = inicio,
            Fin_del_seguro__c = inicio.addYears(1),
            Tipo_originador__c = 'Vendedor Humano',
            Migrado_SICAS__c = true
        );
        insert s;

        Test.startTest();
        Integer n = SICASMigracionUtil.generarPlanesFuturos();
        Test.stopTest();

        System.assertEquals(1, n, 'debe crear 1 plan');

        List<Plan_de_Pagos__c> planes = [SELECT Id FROM Plan_de_Pagos__c WHERE Seguro__c = :s.Id];
        System.assertEquals(1, planes.size(), 'un solo plan asociado');

        List<Recibo_de_Cobro__c> recibos = [
            SELECT Fecha_programada__c FROM Recibo_de_Cobro__c
            WHERE Plan_de_Pagos__c = :planes[0].Id
        ];
        // Todos los recibos creados deben ser >= hoy
        for (Recibo_de_Cobro__c r : recibos) {
            System.assert(r.Fecha_programada__c >= Date.today(),
                'recibo con fecha pasada no deberia existir: ' + r.Fecha_programada__c);
        }
        System.assert(recibos.size() > 0 && recibos.size() <= 12,
            'debe haber entre 1 y 12 recibos futuros, obtuvo ' + recibos.size());
    }

    /**
     * Seguro migrado al contado NO debe producir plan.
     */
    @IsTest
    static void contadoNoProducePlan() {
        Account a = new Account(Name = 'Test Contado', RFC__c = 'XAXX020202000');
        insert a;

        Seguro__c s = new Seguro__c(
            Cliente__c = a.Id,
            Prima_neta__c = 5000,
            Frecuencia_de_pago__c = 'Contado',
            Estatus__c = 'Vigente',
            Inicio_del_seguro__c = Date.today().addMonths(-2),
            Fin_del_seguro__c = Date.today().addMonths(10),
            Tipo_originador__c = 'Vendedor Humano',
            Migrado_SICAS__c = true
        );
        insert s;

        Test.startTest();
        Integer n = SICASMigracionUtil.generarPlanesFuturos();
        Test.stopTest();

        System.assertEquals(0, n, 'Contado no debe generar plan');
        System.assertEquals(0, [SELECT COUNT() FROM Plan_de_Pagos__c WHERE Seguro__c = :s.Id]);
    }

    /**
     * Invocacion idempotente: correr dos veces no duplica planes.
     */
    @IsTest
    static void idempotente() {
        Account a = new Account(Name = 'Test Idem', RFC__c = 'XAXX030303000');
        insert a;

        Seguro__c s = new Seguro__c(
            Cliente__c = a.Id,
            Prima_neta__c = 8000,
            Frecuencia_de_pago__c = 'Trimestral',
            Estatus__c = 'Vigente',
            Inicio_del_seguro__c = Date.today().addMonths(-1),
            Fin_del_seguro__c = Date.today().addMonths(11),
            Tipo_originador__c = 'Vendedor Humano',
            Migrado_SICAS__c = true
        );
        insert s;

        Test.startTest();
        SICASMigracionUtil.generarPlanesFuturos();
        Integer segunda = SICASMigracionUtil.generarPlanesFuturos();
        Test.stopTest();

        System.assertEquals(0, segunda, 'segunda llamada no debe crear planes');
        System.assertEquals(1, [SELECT COUNT() FROM Plan_de_Pagos__c WHERE Seguro__c = :s.Id]);
    }

    /**
     * Insert de Seguro migrado NO dispara la generacion automatica del handler.
     */
    @IsTest
    static void migradoNoDisparaHandler() {
        Account a = new Account(Name = 'Test Handler Skip', RFC__c = 'XAXX040404000');
        insert a;

        Seguro__c s = new Seguro__c(
            Cliente__c = a.Id,
            Prima_neta__c = 6000,
            Frecuencia_de_pago__c = 'Mensual',
            Estatus__c = 'Vigente',
            Inicio_del_seguro__c = Date.today(),
            Fin_del_seguro__c = Date.today().addYears(1),
            Tipo_originador__c = 'Vendedor Humano',
            Migrado_SICAS__c = true
        );

        Test.startTest();
        insert s;
        Test.stopTest();

        // El handler debio saltarlo; no hay plan automatico
        System.assertEquals(0,
            [SELECT COUNT() FROM Plan_de_Pagos__c WHERE Seguro__c = :s.Id],
            'Migrado_SICAS=true debe saltar el handler after insert');
    }
}