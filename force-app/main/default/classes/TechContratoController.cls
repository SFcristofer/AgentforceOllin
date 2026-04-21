public with sharing class TechContratoController {
    @AuraEnabled(cacheable=true)
    public static List<TechContratoWrapper> getContratosList() {
        List<TechContratoWrapper> wrappers = new List<TechContratoWrapper>();
        for (Contrato__c c : TechContratoSelector.getRecentContratos()) {
            wrappers.add(new TechContratoWrapper(c));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveContratoWithRelations(Contrato__c contrato, Map<String, List<String>> relationsMap) {
        try {
            upsert contrato;
            List<Tech_Relacion__c> newRelations = new List<Tech_Relacion__c>();
            if (relationsMap != null) {
                for (String type : relationsMap.keySet()) {
                    for (String relatedId : relationsMap.get(type)) {
                        Tech_Relacion__c rel = new Tech_Relacion__c();
                        rel.Contrato__c = contrato.Id;
                        rel.Tipo__c = type;
                        if (type == 'Contratista') rel.Account__c = (Id)relatedId;
                        else if (type == 'Vendedor') rel.Vendedor__c = (Id)relatedId;
                        newRelations.add(rel);
                    }
                }
            }
            if (!newRelations.isEmpty()) insert newRelations;
            return contrato.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar contrato: ' + e.getMessage());
        }
    }
}