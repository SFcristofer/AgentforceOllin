/**
 * HubGestionControllerTest - v6.1
 * ---------------------------------------------------------------------------
 * Cobertura minima para deploy (>75%).
 * Incluye casos:
 *   - getHubData returns KPIs + buckets mensuales correctos
 *   - marcarNoRenovada actualiza estatus y motivo
 *   - marcarNoRenovada valida entradas nulas y motivos invalidos
 *
 * Notas v6.1:
 *   - El test no crea Recibo_de_Cobro__c, solo Seguro__c. El fix de picklist
 *     values en el controller (Programado->Pendiente, Cobrado->Pagado) no
 *     requiere cambios aqui. Los queries de KPIs de cobranza devolveran 0
 *     en el contexto del test, lo cual es correcto.
 * ---------------------------------------------------------------------------
 */
@IsTest
private class HubGestionControllerTest {

    @TestSetup
    static void setup() {
        // Cuenta cliente
        Account acc = new Account(Name = 'Cliente Test');
        insert acc;

        // Seguros: 1 atrasada, 1 mes actual, 1 mes siguiente
        Date today = Date.today();
        Date finAtrasada = today.addDays(-10);
        Date finMesActual = Date.newInstance(today.year(), today.month(), 28);
        Date finMesSig = finMesActual.addMonths(1);

        List<Seguro__c> segs = new List<Seguro__c>{
            new Seguro__c(
                Numero_poliza__c = 'ATR-001',
                Ramo__c = 'Auto',
                Cliente__c = acc.Id,
                Fin_del_seguro__c = finAtrasada,
                Estatus__c = 'Vigente',
                Prima_neta__c = 5000
            ),
            new Seguro__c(
                Numero_poliza__c = 'MES-001',
                Ramo__c = 'GMM',
                Cliente__c = acc.Id,
                Fin_del_seguro__c = finMesActual,
                Estatus__c = 'Por renovar',
                Prima_neta__c = 12000
            ),
            new Seguro__c(
                Numero_poliza__c = 'SIG-001',
                Ramo__c = 'Vida/PPR',
                Cliente__c = acc.Id,
                Fin_del_seguro__c = finMesSig,
                Estatus__c = 'Vigente',
                Prima_neta__c = 8000
            )
        };
        insert segs;
    }

    @IsTest
    static void testGetHubData_returnsBuckets() {
        Test.startTest();
        HubGestionController.HubData data = HubGestionController.getHubData();
        Test.stopTest();

        System.assertNotEquals(null, data, 'HubData no debe ser null');
        System.assertNotEquals(null, data.kpis, 'KPIs no deben ser null');
        System.assertNotEquals(null, data.renovaciones, 'Renovaciones no deben ser null');
        System.assertEquals(1, data.renovaciones.atrasadas.size(), 'Debe haber 1 atrasada');
        System.assert(data.renovaciones.mesActual.size() >= 1, 'Debe haber ≥1 en mes actual');
        System.assertEquals(1, data.renovaciones.mesSiguiente.size(), 'Debe haber 1 en mes siguiente');
        System.assert(!data.motivosNoRenovacion.isEmpty(), 'Motivos no renovación deben poblarse');
    }

    @IsTest
    static void testMarcarNoRenovada_happyPath() {
        Seguro__c s = [SELECT Id, Motivo_No_Renovacion__c FROM Seguro__c WHERE Numero_poliza__c = 'ATR-001' LIMIT 1];
        // Tomar primer motivo activo del picklist
        String motivo;
        for (Schema.PicklistEntry pe : Seguro__c.Motivo_No_Renovacion__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) { motivo = pe.getValue(); break; }
        }
        System.assertNotEquals(null, motivo, 'Debe existir al menos 1 motivo activo');

        Test.startTest();
        HubGestionController.marcarNoRenovada(s.Id, motivo);
        Test.stopTest();

        Seguro__c after = [SELECT Estatus__c, Motivo_No_Renovacion__c FROM Seguro__c WHERE Id = :s.Id];
        System.assertEquals('No renovada', after.Estatus__c);
        System.assertEquals(motivo, after.Motivo_No_Renovacion__c);
    }

    @IsTest
    static void testMarcarNoRenovada_nullId() {
        Boolean threw = false;
        try {
            HubGestionController.marcarNoRenovada(null, 'Precio');
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Debe lanzar AuraHandledException con seguroId null');
    }

    @IsTest
    static void testMarcarNoRenovada_motivoInvalido() {
        Seguro__c s = [SELECT Id FROM Seguro__c LIMIT 1];
        Boolean threw = false;
        try {
            HubGestionController.marcarNoRenovada(s.Id, 'MOTIVO_INEXISTENTE_XYZ');
        } catch (AuraHandledException e) {
            threw = true;
        }
        System.assert(threw, 'Debe lanzar AuraHandledException con motivo inválido');
    }
}