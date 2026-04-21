public class TechProyectoWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String contrato { get; set; }
    @AuraEnabled public Datetime fechaCreacion { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }

    public TechProyectoWrapper(Proyecto__c p) {
        this.id = p.Id;
        this.name = p.Name;
        this.contrato = p.Contrato__r != null ? p.Contrato__r.Name : 'Sin Contrato';
        this.fechaCreacion = p.CreatedDate;
        
        // Simulación de estatus para la interfaz (puedes cambiarlo después por un campo real)
        this.estatus = 'En Proceso';
        this.estatusClass = 'airtable-badge-green';
    }
}