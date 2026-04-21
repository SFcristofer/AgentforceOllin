public with sharing class TechBeneficiarioSelector {
    public static List<Beneficiario__c> getRecentBeneficiarios() {
        return [
            SELECT Id, Name, CreatedDate,
                   (SELECT Tipo__c, Fianza__r.Name FROM Relaciones_Tecnicas_Beneficiario__r)
            FROM Beneficiario__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}