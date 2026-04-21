/**
 * Tests de las automatizaciones del Modulo de Gestion.
 * Cubre:
 *  - SeguroAutomationHandler.handleAfterInsert (genera Plan + Recibos)
 *  - SeguroAutomationHandler.handleAfterUpdate (crea Oportunidad renovacion)
 *  - ScheduledReciboVencido
 *  - ScheduledSeguroRenovacion
 *  - ScheduledReciboTaskMora
 *
 * Helpers de setup crean registros minimos para que los inserts pasen
 * sin depender de datos externos.
 */
@IsTest
private class SeguroAutomationTest {

    /**
     * Crea una cuenta y retorna su Id (person account si esta habilitado,
     * o business account estandar).
     */
    private static Id makeAccount() {
        Account a = new Account(Name = 'Cliente Test');
        insert a;
        return a.Id;
    }

    private static Seguro__c makeSeguro(Id accountId, String frecuencia, String originador, Date inicio) {
        Seguro__c s = new Seguro__c();
        s.Cliente__c              = accountId;
        s.Numero_poliza__c        = 'TEST-' + Datetime.now().getTime();
        s.Ramo__c                 = 'Auto';
        s.Prima_neta__c           = 12000;
        s.Frecuencia_de_pago__c   = frecuencia;
        s.Estatus__c              = 'Vigente';
        s.Inicio_del_seguro__c    = inicio;
        s.Fin_del_seguro__c       = inicio.addYears(1);
        s.Tipo_originador__c      = originador;
        return s;
    }

    @IsTest
    static void insertSeguroMensual_generaPlanY12Recibos() {
        Id acc = makeAccount();
        Seguro__c s = makeSeguro(acc, 'Mensual', 'Vendedor Humano', Date.today());

        Test.startTest();
        insert s;
        Test.stopTest();

        List<Plan_de_Pagos__c> planes = [
            SELECT Id, Num_recibos__c, Monto__c, Frecuencia__c, Estado__c
            FROM Plan_de_Pagos__c WHERE Seguro__c = :s.Id
        ];
        System.assertEquals(1, planes.size(), 'Debe crear un plan por seguro');
        System.assertEquals(12, planes[0].Num_recibos__c, 'Mensual = 12 recibos');
        System.assertEquals('Activo', planes[0].Estado__c);
        System.assertEquals('Mensual', planes[0].Frecuencia__c);

        List<Recibo_de_Cobro__c> recibos = [
            SELECT Id, Numero__c, Monto_programado__c, Estado__c
            FROM Recibo_de_Cobro__c WHERE Plan_de_Pagos__c = :planes[0].Id
            ORDER BY Numero__c
        ];
        System.assertEquals(12, recibos.size(), 'Deben crearse 12 recibos');
        Decimal suma = 0;
        for (Recibo_de_Cobro__c r : recibos) {
            System.assertEquals('Pendiente', r.Estado__c);
            suma += r.Monto_programado__c;
        }
        System.assertEquals(12000, suma, 'Suma de recibos debe igualar la prima');
    }

    @IsTest
    static void insertSeguroDigital_omitePlan() {
        Id acc = makeAccount();
        Seguro__c s = makeSeguro(acc, 'Contado', 'IA (Agentforce)', Date.today());

        Test.startTest();
        insert s;
        Test.stopTest();

        Integer planes = [SELECT COUNT() FROM Plan_de_Pagos__c WHERE Seguro__c = :s.Id];
        System.assertEquals(0, planes, 'Digital no debe generar plan remanente');
    }

    @IsTest
    static void insertSeguroQuincenal_genera24Recibos() {
        Id acc = makeAccount();
        Seguro__c s = makeSeguro(acc, 'Quincenal', 'Vendedor Humano', Date.today());
        insert s;
        Integer n = [SELECT COUNT() FROM Recibo_de_Cobro__c
                     WHERE Plan_de_Pagos__r.Seguro__c = :s.Id];
        System.assertEquals(24, n);
    }

    @IsTest
    static void updateAPorRenovar_creaOpportunity() {
        Id acc = makeAccount();
        Seguro__c s = makeSeguro(acc, 'Contado', 'Vendedor Humano', Date.today());
        insert s;

        Integer oppsAntes = [SELECT COUNT() FROM Opportunity WHERE AccountId = :acc];

        Test.startTest();
        s.Estatus__c = 'Por renovar';
        update s;
        Test.stopTest();

        Integer oppsDespues = [SELECT COUNT() FROM Opportunity WHERE AccountId = :acc];
        System.assertEquals(oppsAntes + 1, oppsDespues,
            'Debe crear exactamente una Oportunidad al transicionar a Por renovar');

        Opportunity op = [SELECT Name, StageName, Type, Amount
                          FROM Opportunity WHERE AccountId = :acc ORDER BY CreatedDate DESC LIMIT 1];
        System.assert(op.Name.startsWith('Renovacion'), 'Nombre debe empezar con Renovacion');
        System.assertEquals('Prospecting', op.StageName);
        System.assertEquals(12000, op.Amount);
    }

    @IsTest
    static void scheduledReciboVencido_marcaVencidos() {
        Id acc = makeAccount();
        Seguro__c s = makeSeguro(acc, 'Mensual', 'Vendedor Humano', Date.today().addMonths(-3));
        insert s;

        // Los recibos se crearon con fechas pasadas; algunos ya deberian estar vencidos.
        Integer pendientesAntes = [SELECT COUNT() FROM Recibo_de_Cobro__c
            WHERE Plan_de_Pagos__r.Seguro__c = :s.Id AND Estado__c = 'Pendiente'
              AND Fecha_programada__c < TODAY];
        System.assert(pendientesAntes > 0, 'Setup: debe haber recibos pendientes con fecha pasada');

        Test.startTest();
        Integer actualizados = ScheduledReciboVencido.runNow();
        Test.stopTest();

        System.assertEquals(pendientesAntes, actualizados);
        Integer vencidos = [SELECT COUNT() FROM Recibo_de_Cobro__c
            WHERE Plan_de_Pagos__r.Seguro__c = :s.Id AND Estado__c = 'Vencido'];
        System.assert(vencidos >= pendientesAntes);
    }

    @IsTest
    static void scheduledReciboVencido_schedulable() {
        Test.startTest();
        String cron = '0 0 3 * * ?';
        System.schedule('TestReciboVencido', cron, new ScheduledReciboVencido());
        Test.stopTest();
    }

    @IsTest
    static void scheduledSeguroRenovacion_transicionaPorRenovar() {
        Id acc = makeAccount();
        // Seguro que vence en 30 dias -> debe pasar a Por renovar (<= 60).
        Seguro__c s = makeSeguro(acc, 'Contado', 'Vendedor Humano', Date.today().addDays(-335));
        // Override: que termine en 30 dias exactos.
        s.Fin_del_seguro__c = Date.today().addDays(30);
        insert s;

        Test.startTest();
        Map<String, Integer> result = ScheduledSeguroRenovacion.runNow();
        Test.stopTest();

        System.assert(result.get('por_renovar') >= 1);
        Seguro__c reloaded = [SELECT Estatus__c FROM Seguro__c WHERE Id = :s.Id];
        System.assertEquals('Por renovar', reloaded.Estatus__c);
    }

    @IsTest
    static void scheduledSeguroRenovacion_marcaNoRenovada() {
        Id acc = makeAccount();
        Seguro__c s = makeSeguro(acc, 'Contado', 'Vendedor Humano', Date.today().addDays(-400));
        s.Fin_del_seguro__c = Date.today().addDays(-15);  // vencio hace 15 dias
        insert s;

        Test.startTest();
        Map<String, Integer> result = ScheduledSeguroRenovacion.runNow();
        Test.stopTest();

        System.assert(result.get('no_renovada') >= 1);
        Seguro__c reloaded = [SELECT Estatus__c FROM Seguro__c WHERE Id = :s.Id];
        System.assertEquals('No renovada', reloaded.Estatus__c);
    }

    @IsTest
    static void scheduledSeguroRenovacion_schedulable() {
        Test.startTest();
        System.schedule('TestSeguroRenovacion', '0 0 4 * * ?', new ScheduledSeguroRenovacion());
        Test.stopTest();
    }

    @IsTest
    static void scheduledReciboTaskMora_creaTareas() {
        Id acc = makeAccount();
        Seguro__c s = makeSeguro(acc, 'Mensual', 'Vendedor Humano', Date.today().addMonths(-3));
        insert s;

        // Marcar todos los vencidos primero
        ScheduledReciboVencido.runNow();

        Test.startTest();
        Integer nuevas = ScheduledReciboTaskMora.runNow();
        Test.stopTest();

        System.assert(nuevas >= 0, 'No debe fallar');
        // Idempotencia: una segunda corrida no debe duplicar.
        Integer tareasDespues1 = [SELECT COUNT() FROM Task WHERE Subject LIKE 'Cobranza mora%'];
        ScheduledReciboTaskMora.runNow();
        Integer tareasDespues2 = [SELECT COUNT() FROM Task WHERE Subject LIKE 'Cobranza mora%'];
        System.assertEquals(tareasDespues1, tareasDespues2, 'No debe crear duplicados');
    }

    @IsTest
    static void scheduledReciboTaskMora_schedulable() {
        Test.startTest();
        System.schedule('TestReciboTaskMora', '0 0 5 * * ?', new ScheduledReciboTaskMora());
        Test.stopTest();
    }
}