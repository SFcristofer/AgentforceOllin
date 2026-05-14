@IsTest
public class Tech_OpportunityManagerTest {
    
    @TestSetup
    static void setup() {
        // Obtener el RecordTypeId de Person Account
        Id personAccountRTId = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'PersonAccount' LIMIT 1].Id;

        // Crear una Cuenta (PersonAccount)
        Account acc = new Account(
            FirstName = 'Test',
            LastName = 'Cliente',
            PersonEmail = 'test.cliente@gmail.com',
            RecordTypeId = personAccountRTId
        );
        insert acc;
        
        // Crear un Lead
        Lead l = new Lead(
            FirstName = 'Test',
            LastName = 'Prospecto',
            Email = 'test.prospecto@gmail.com',
            Company = 'Test Co'
        );
        insert l;
    }

    @IsTest
    static void testCreateOpportunityForAccount() {
        Account acc = [SELECT Id, Name FROM Account WHERE PersonEmail = 'test.cliente@gmail.com' LIMIT 1];
        
        Tech_OpportunityManager.OpportunityRequest req = new Tech_OpportunityManager.OpportunityRequest();
        req.recordId = acc.Id;
        req.clientType = 'Cliente';
        req.ramo = 'Auto';
        req.clientName = acc.Name;
        req.amount = 5000;
        req.vehicleYear = 2024;
        req.vehicleModel = 'Tesla Model 3';
        
        Test.startTest();
        List<Tech_OpportunityManager.OpportunityResult> results = Tech_OpportunityManager.manageOpportunity(new List<Tech_OpportunityManager.OpportunityRequest>{req});
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Debe devolver un resultado');
        System.assertEquals(true, results[0].isSuccess, 'La operación debe ser exitosa');
        
        Opportunity opp = [SELECT Id, AccountId, Prospecto__c, Ramo__c, Ano_vehiculo__c, Modelo__c FROM Opportunity WHERE Id = :results[0].opportunityId];
        System.assertEquals(acc.Id, opp.AccountId, 'Debe estar vinculada a la Cuenta');
        System.assertEquals(null, opp.Prospecto__c, 'No debe estar vinculada a un Prospecto');
        System.assertEquals('Auto', opp.Ramo__c);
        System.assertEquals(2024, opp.Ano_vehiculo__c);
    }

    @IsTest
    static void testCreateOpportunityForLead() {
        Lead l = [SELECT Id, Name FROM Lead WHERE Email = 'test.prospecto@gmail.com' LIMIT 1];
        
        Tech_OpportunityManager.OpportunityRequest req = new Tech_OpportunityManager.OpportunityRequest();
        req.recordId = l.Id;
        req.clientType = 'Prospecto';
        req.ramo = 'Vida';
        req.clientName = l.Name;
        req.amount = 1000000;
        req.technicalNotes = 'Plan de ahorro para el retiro';
        
        Test.startTest();
        List<Tech_OpportunityManager.OpportunityResult> results = Tech_OpportunityManager.manageOpportunity(new List<Tech_OpportunityManager.OpportunityRequest>{req});
        Test.stopTest();
        
        System.assertEquals(true, results[0].isSuccess);
        
        Opportunity opp = [SELECT Id, AccountId, Prospecto__c, Ramo__c, Description FROM Opportunity WHERE Id = :results[0].opportunityId];
        System.assertEquals(l.Id, opp.Prospecto__c, 'Debe estar vinculada al Prospecto');
        System.assertEquals('Vida', opp.Ramo__c);
        System.assert(opp.Description.contains('Plan de ahorro'), 'La descripción debe contener las notas');
    }
}
