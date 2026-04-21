public with sharing class TechAmpliacionController {
    @AuraEnabled(cacheable=true)
    public static List<TechAmpliacionWrapper> getAmpliacionesList() {
        List<TechAmpliacionWrapper> wrappers = new List<TechAmpliacionWrapper>();
        for (Endoso__c e : TechAmpliacionSelector.getRecentAmpliaciones()) {
            wrappers.add(new TechAmpliacionWrapper(e));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveAmpliacionWithRelations(Endoso__c ampliacion, Map<String, List<String>> relationsMap) {
        try {
            upsert ampliacion;
            List<Tech_Relacion__c> newRelations = new List<Tech_Relacion__c>();
            if (relationsMap != null) {
                for (String type : relationsMap.keySet()) {
                    for (String relatedId : relationsMap.get(type)) {
                        Tech_Relacion__c rel = new Tech_Relacion__c();
                        rel.Endoso__c = ampliacion.Id;
                        rel.Tipo__c = type;
                        if (type == 'Fianza') rel.Fianza__c = (Id)relatedId;
                        newRelations.add(rel);
                    }
                }
            }
            if (!newRelations.isEmpty()) insert newRelations;
            return ampliacion.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar ampliación: ' + e.getMessage());
        }
    }
}