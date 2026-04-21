public with sharing class TechLookupController {
    @AuraEnabled(cacheable=true)
    public static List<LookupResult> searchRecords(String searchTerm, String objectApiName) {
        String query = 'SELECT Id, Name FROM ' + objectApiName + 
                       ' WHERE Name LIKE \'%' + String.escapeSingleQuotes(searchTerm) + '%\' ' +
                       ' WITH USER_MODE LIMIT 10';
        
        List<LookupResult> results = new List<LookupResult>();
        for (SObject so : Database.query(query)) {
            results.add(new LookupResult((String)so.get('Name'), so.Id));
        }
        return results;
    }

    public class LookupResult {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public LookupResult(String label, String value) {
            this.label = label;
            this.value = value;
        }
    }
}