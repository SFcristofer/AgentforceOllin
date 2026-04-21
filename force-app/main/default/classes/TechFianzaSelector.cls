public with sharing class TechFianzaSelector {
    public static List<Fianza__c> getRecentFianzas() {
        return [
            SELECT Id, Name, No_Contrato__c, 
                   Contratista__c, Contratista__r.Name, 
                   Vendedor__c, Vendedor__r.Name, 
                   Estatus__c, Monto_Afianzado__c, Fecha_de_Emisi_n__c, Afianzadora__c,
                   (SELECT Id, Tipo__c, Contrato__r.Name, Account__r.Name, Vendedor__r.Name, Endoso__r.Name
                    FROM Relaciones_Tecnicas_Fianza__r)
            FROM Fianza__c
            ORDER BY CreatedDate DESC
            LIMIT 50
        ];
    }
}