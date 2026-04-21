public with sharing class TechAmpliacionSelector {
    public static List<Endoso__c> getRecentAmpliaciones() {
        return [
            SELECT Id, Name, Fianza__c, Fianza__r.Name, CreatedDate,
                   (SELECT Tipo__c, Fianza__r.Name FROM Relaciones_Tecnicas_Endoso__r)
            FROM Endoso__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}