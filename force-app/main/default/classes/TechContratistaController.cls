public with sharing class TechContratistaController {
    @AuraEnabled(cacheable=true)
    public static List<TechContratistaWrapper> getContratistaList() {
        List<TechContratistaWrapper> wrappers = new List<TechContratistaWrapper>();
        for (Contratista__c c : TechContratistaSelector.getRecentContratistas()) {
            wrappers.add(new TechContratistaWrapper(c));
        }
        return wrappers;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchFianzas(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Fianza__c f : [SELECT Id, Name FROM Fianza__c WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            results.add(new Map<String,String>{ 'id' => f.Id, 'name' => f.Name });
        }
        return results;
    }

    @AuraEnabled
    public static List<Map<String,String>> searchContratos(String term) {
        String q = '%' + String.escapeSingleQuotes(term) + '%';
        List<Map<String,String>> results = new List<Map<String,String>>();
        for (Contrato__c c : [SELECT Id, Name FROM Contrato__c WHERE Name LIKE :q ORDER BY Name LIMIT 10]) {
            results.add(new Map<String,String>{ 'id' => c.Id, 'name' => c.Name });
        }
        return results;
    }

    @AuraEnabled
    public static void addRelacion(String contratistaId, String relatedId, String tipo) {
        try {
            Tech_Relacion__c rel = new Tech_Relacion__c();
            rel.Contratista__c = (Id)contratistaId;
            rel.Tipo__c = tipo;
            if (tipo == 'Fianza') rel.Fianza__c = (Id)relatedId;
            else if (tipo == 'Contrato') rel.Contrato__c = (Id)relatedId;
            insert rel;
        } catch (Exception e) {
            throw new AuraHandledException('Error al agregar relación: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static String saveContratistaWithRelations(Contratista__c contratista, Map<String, List<String>> relationsMap) {
        try {
            upsert contratista;
            List<Tech_Relacion__c> newRelations = new List<Tech_Relacion__c>();
            if (relationsMap != null) {
                for (String type : relationsMap.keySet()) {
                    for (String relatedId : relationsMap.get(type)) {
                        Tech_Relacion__c rel = new Tech_Relacion__c();
                        rel.Account__c = contratista.Id; // Usamos Account__c como Lookup genérico en el puente
                        rel.Tipo__c = type;
                        if (type == 'Fianza') rel.Fianza__c = (Id)relatedId;
                        else if (type == 'Contrato') rel.Contrato__c = (Id)relatedId;
                        newRelations.add(rel);
                    }
                }
            }
            if (!newRelations.isEmpty()) insert newRelations;
            return contratista.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar contratista: ' + e.getMessage());
        }
    }
}