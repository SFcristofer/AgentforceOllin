public with sharing class TechProyectoSelector {
    public static List<Proyecto__c> getRecentProyectos() {
        return [
            SELECT Id, Name, Contrato__r.Name, CreatedDate
            FROM Proyecto__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}