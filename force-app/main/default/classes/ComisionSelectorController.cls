public with sharing class ComisionSelectorController {
    
    @AuraEnabled(cacheable=true)
    public static List<String> getInstituciones() {
        Set<String> insts = new Set<String>();
        for (Tabla_Comision__c tc : [SELECT Institucion__c FROM Tabla_Comision__c WHERE Institucion__c != null]) {
            insts.add(tc.Institucion__c);
        }
        List<String> result = new List<String>(insts);
        result.sort();
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getRamos(String institucion) {
        Set<String> ramos = new Set<String>();
        for (Tabla_Comision__c tc : [SELECT Ramo__c FROM Tabla_Comision__c 
                WHERE Institucion__c = :institucion AND Ramo__c != null]) {
            ramos.add(tc.Ramo__c);
        }
        List<String> result = new List<String>(ramos);
        result.sort();
        return result;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getSubproductos(String institucion, String ramo) {
        Set<String> subs = new Set<String>();
        for (Tabla_Comision__c tc : [SELECT Subproducto__c FROM Tabla_Comision__c 
                WHERE Institucion__c = :institucion AND Ramo__c = :ramo AND Subproducto__c != null]) {
            subs.add(tc.Subproducto__c);
        }
        List<String> result = new List<String>(subs);
        result.sort();
        return result;
    }
    
    @AuraEnabled
    public static Map<String, Object> saveSelection(String oppId, String institucion, String ramo, String subproducto) {
        Map<String, Object> response = new Map<String, Object>();
        try {
            Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :oppId];
            opp.Institucion__c = institucion;
            opp.Ramo__c = ramo;
            if (String.isNotBlank(subproducto)) {
                opp.Subproducto__c = subproducto;
            }
            update opp;
            
            Opportunity updated = [SELECT PctComisionOllin__c FROM Opportunity WHERE Id = :oppId];
            response.put('success', true);
            response.put('pctComision', updated.PctComisionOllin__c);
        } catch (Exception e) {
            response.put('success', false);
            response.put('error', e.getMessage());
        }
        return response;
    }
}