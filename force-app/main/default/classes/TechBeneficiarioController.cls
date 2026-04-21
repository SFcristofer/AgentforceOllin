public with sharing class TechBeneficiarioController {
    @AuraEnabled(cacheable=true)
    public static List<TechBeneficiarioWrapper> getBeneficiarioList() {
        List<TechBeneficiarioWrapper> wrappers = new List<TechBeneficiarioWrapper>();
        for (Beneficiario__c b : TechBeneficiarioSelector.getRecentBeneficiarios()) {
            wrappers.add(new TechBeneficiarioWrapper(b));
        }
        return wrappers;
    }

    @AuraEnabled
    public static String saveBeneficiarioWithRelations(Beneficiario__c beneficiario, Map<String, List<String>> relationsMap) {
        try {
            upsert beneficiario;
            List<Tech_Relacion__c> newRelations = new List<Tech_Relacion__c>();
            if (relationsMap != null) {
                for (String type : relationsMap.keySet()) {
                    for (String relatedId : relationsMap.get(type)) {
                        Tech_Relacion__c rel = new Tech_Relacion__c();
                        rel.Account__c = beneficiario.Id; // Usamos Account__c genérico
                        rel.Tipo__c = type;
                        if (type == 'Fianza') rel.Fianza__c = (Id)relatedId;
                        else if (type == 'Contrato') rel.Contrato__c = (Id)relatedId;
                        newRelations.add(rel);
                    }
                }
            }
            if (!newRelations.isEmpty()) insert newRelations;
            return beneficiario.Id;
        } catch (Exception e) {
            throw new AuraHandledException('Error al guardar beneficiario: ' + e.getMessage());
        }
    }
}