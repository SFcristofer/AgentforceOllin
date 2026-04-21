public with sharing class TechAfianzadoController {
    @AuraEnabled(cacheable=true)
    public static List<TechAfianzadoWrapper> getAfianzadoList() {
        List<TechAfianzadoWrapper> wrappers = new List<TechAfianzadoWrapper>();
        for (Account a : TechAfianzadoSelector.getRecentAfianzados()) {
            wrappers.add(new TechAfianzadoWrapper(a));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveAfianzadoWithRelations(Account account, Map<String, List<String>> relationsMap) {
        try {
            upsert account;
            List<Tech_Relacion__c> newRelations = new List<Tech_Relacion__c>();
            if (relationsMap != null) {
                for (String type : relationsMap.keySet()) {
                    for (String relatedId : relationsMap.get(type)) {
                        Tech_Relacion__c rel = new Tech_Relacion__c();
                        rel.Account__c = account.Id;
                        rel.Tipo__c = type;
                        if (type == 'Fianza') rel.Fianza__c = (Id)relatedId;
                        newRelations.add(rel);
                    }
                }
            }
            if (!newRelations.isEmpty()) insert newRelations;
            return account.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar afianzado: ' + e.getMessage());
        }
    }
}