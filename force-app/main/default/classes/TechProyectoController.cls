public with sharing class TechProyectoController {
    @AuraEnabled(cacheable=true)
    public static List<TechProyectoWrapper> getProyectosList() {
        List<TechProyectoWrapper> wrappers = new List<TechProyectoWrapper>();
        for (Proyecto__c p : TechProyectoSelector.getRecentProyectos()) {
            wrappers.add(new TechProyectoWrapper(p));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveProyectoWithRelations(Proyecto__c proyecto, Map<String, List<String>> relationsMap) {
        try {
            upsert proyecto;
            List<Tech_Relacion__c> newRelations = new List<Tech_Relacion__c>();
            if (relationsMap != null) {
                for (String type : relationsMap.keySet()) {
                    for (String relatedId : relationsMap.get(type)) {
                        Tech_Relacion__c rel = new Tech_Relacion__c();
                        rel.Proyecto__c = proyecto.Id;
                        rel.Tipo__c = type;
                        if (type == 'Beneficiario') rel.Account__c = (Id)relatedId;
                        else if (type == 'Contrato') rel.Contrato__c = (Id)relatedId;
                        newRelations.add(rel);
                    }
                }
            }
            if (!newRelations.isEmpty()) insert newRelations;
            return proyecto.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar proyecto: ' + e.getMessage());
        }
    }
}