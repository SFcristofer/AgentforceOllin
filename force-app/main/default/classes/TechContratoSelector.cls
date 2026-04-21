public with sharing class TechContratoSelector {
    public static List<Contrato__c> getRecentContratos() {
        return [
            SELECT Id, Name, CreatedDate
            FROM Contrato__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}