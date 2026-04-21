public class TechAfianzadoWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public String rfc { get; set; }
    @AuraEnabled public List<String> fianzas { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }

    public TechAfianzadoWrapper(Account a) {
        this.id = a.Id;
        this.name = a.Name;
        this.rfc = a.RFC__c;
        this.fianzas = new List<String>();

        for (Tech_Relacion__c rel : a.Relaciones_Tecnicas_Account__r) {
            if (rel.Tipo__c == 'Fianza' && rel.Fianza__r.Name != null) this.fianzas.add(rel.Fianza__r.Name);
        }

        this.estatus = 'Activo';
        this.estatusClass = 'airtable-badge-green';
    }
}