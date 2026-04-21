public with sharing class TechContratistaSelector {
    public static List<Contratista__c> getRecentContratistas() {
        return [
            SELECT Id, Name, CreatedDate,
                   (SELECT Tipo__c, Fianza__r.Name, Contrato__r.Name FROM Relaciones_Tecnicas_Contratista__r)
            FROM Contratista__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}