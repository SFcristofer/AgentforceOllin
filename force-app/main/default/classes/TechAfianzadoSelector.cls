public with sharing class TechAfianzadoSelector {
    public static List<Account> getRecentAfianzados() {
        return [
            SELECT Id, Name, RFC__c, CreatedDate,
                   (SELECT Tipo__c, Fianza__r.Name FROM Relaciones_Tecnicas_Account__r)
            FROM Account
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}