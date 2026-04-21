public with sharing class TechAfianzadoFieldsController {
    @AuraEnabled(cacheable=true)
    public static List<FieldInfo> getAfianzadoFields() {
        List<FieldInfo> fieldList = new List<FieldInfo>();
        Map<String, Schema.SObjectField> fieldsMap = Schema.SObjectType.Account.fields.getMap();
        for (Schema.SObjectField field : fieldsMap.values()) {
            Schema.DescribeFieldResult descField = field.getDescribe();
            if (descField.isCreateable() || descField.getName() == 'Name') {
                fieldList.add(new FieldInfo(descField.getLabel(), descField.getName(), String.valueOf(descField.getType())));
            }
        }
        return fieldList;
    }
    public class FieldInfo {
        @AuraEnabled public String label;
        @AuraEnabled public String apiName;
        @AuraEnabled public String type;
        public FieldInfo(String label, String apiName, String type) {
            this.label = label;
            this.apiName = apiName;
            this.type = type;
        }
    }
}