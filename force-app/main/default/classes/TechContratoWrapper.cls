public class TechContratoWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String contratista { get; set; }
    @AuraEnabled public Decimal monto { get; set; }
    @AuraEnabled public Date fechaInicio { get; set; }
    @AuraEnabled public Date fechaFin { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }

    public TechContratoWrapper(Contrato__c c) {
        this.id = c.Id;
        this.name = c.Name;
        this.contratista = 'N/A';
        this.monto = 0;
        this.fechaInicio = null;
        this.fechaFin = null;
        this.estatus = 'N/A';
        this.estatusClass = 'airtable-badge-gray';
    }
}