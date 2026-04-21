public class TechBeneficiarioWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String rfc { get; set; }
    @AuraEnabled public List<String> fianzas { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }

    public TechBeneficiarioWrapper(Beneficiario__c b) {
        this.id = b.Id;
        this.name = b.Name;
        this.rfc = 'Ver en Salesforce';
        this.fianzas = new List<String>();

        for (Tech_Relacion__c rel : b.Relaciones_Tecnicas_Beneficiario__r) {
            if (rel.Tipo__c == 'Fianza' && rel.Fianza__r.Name != null) this.fianzas.add(rel.Fianza__r.Name);
        }

        this.estatus = 'Activo';
        this.estatusClass = 'airtable-badge-green';
    }
}