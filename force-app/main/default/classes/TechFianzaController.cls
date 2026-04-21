public with sharing class TechFianzaController {
    @AuraEnabled(cacheable=true)
    public static List<TechFianzaWrapper> getFianzasList() {
        List<TechFianzaWrapper> wrappers = new List<TechFianzaWrapper>();
        for (Fianza__c f : TechFianzaSelector.getRecentFianzas()) {
            wrappers.add(new TechFianzaWrapper(f));
        }
        return wrappers;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchContratistas(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Account a : [SELECT Id, Name FROM Account WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            results.add(new Map<String,String>{ 'id' => a.Id, 'name' => a.Name });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchVendedores(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Vendedores__c v : [SELECT Id, Name FROM Vendedores__c WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            results.add(new Map<String,String>{ 'id' => v.Id, 'name' => v.Name });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchContratosForFianza(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Contrato__c c : [SELECT Id, Name FROM Contrato__c WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            results.add(new Map<String,String>{ 'id' => c.Id, 'name' => c.Name });
        }
        return results;
    }

    @AuraEnabled
    public static void deleteRelacion(String relId) {
        try {
            delete [SELECT Id FROM Tech_Relacion__c WHERE Id = :relId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException('Error al eliminar relación: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void addRelacionFianza(String fianzaId, String relatedId, String tipo) {
        try {
            Tech_Relacion__c rel = new Tech_Relacion__c();
            rel.Fianza__c = (Id)fianzaId;
            rel.Tipo__c   = tipo;
            if (tipo == 'Contratista') rel.Account__c    = (Id)relatedId;
            else if (tipo == 'Vendedor')  rel.Vendedor__c   = (Id)relatedId;
            else if (tipo == 'Contrato')  rel.Contrato__c   = (Id)relatedId;
            insert rel;
        } catch (Exception e) {
            throw new AuraHandledException('Error al agregar relación: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String saveFianzaWithRelations(Fianza__c fianza, Map<String, List<String>> relationsMap) {
        try {
            upsert fianza;
            
            List<Tech_Relacion__c> newRelations = new List<Tech_Relacion__c>();
            
            if (relationsMap != null) {
                for (String type : relationsMap.keySet()) {
                    for (String relatedId : relationsMap.get(type)) {
                        Tech_Relacion__c rel = new Tech_Relacion__c();
                        rel.Fianza__c = fianza.Id;
                        rel.Tipo__c = type;
                        
                        if (type == 'Contrato') rel.Contrato__c = (Id)relatedId;
                        else if (type == 'Endoso') rel.Endoso__c = (Id)relatedId;
                        else if (type == 'Contratista') rel.Account__c = (Id)relatedId;
                        else if (type == 'Vendedor') rel.Vendedor__c = (Id)relatedId;
                        
                        newRelations.add(rel);
                    }
                }
            }
            
            if (!newRelations.isEmpty()) {
                insert newRelations;
            }
            return fianza.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar fianza y relaciones: ' + e.getMessage());
        }
    }
}