public class TechContratistaWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String rfc { get; set; }
    @AuraEnabled public List<String> fianzas { get; set; }
    @AuraEnabled public List<String> contratos { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @ AuraEnabled public String estatusClass { get; set; }

    public TechContratistaWrapper(Contratista__c c) {
        this.id = c.Id;
        this.name = c.Name;
        this.rfc = 'Ver en Salesforce';
        this.fianzas = new List<String>();
        this.contratos = new List<String>();

        for (Tech_Relacion__c rel : c.Relaciones_Tecnicas_Contratista__r) {
            if (rel.Tipo__c == 'Fianza' && rel.Fianza__r.Name != null) this.fianzas.add(rel.Fianza__r.Name);
            else if (rel.Tipo__c == 'Contrato' && rel.Contrato__r.Name != null) this.contratos.add(rel.Contrato__r.Name);
        }

        this.estatus = 'Activo';
        this.estatusClass = 'airtable-badge-green';
    }
}