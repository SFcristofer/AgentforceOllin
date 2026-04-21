public class TechAmpliacionWrapper {
    @AuraEnabled public String id { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public List<String> fianzas { get; set; }
    @AuraEnabled public String estatus { get; set; }
    @AuraEnabled public String estatusClass { get; set; }

    public TechAmpliacionWrapper(Endoso__c e) {
        this.id = e.Id;
        this.name = e.Name;
        this.fianzas = new List<String>();
        
        // Agregar principal
        if (e.Fianza__r != null) {
            this.fianzas.add(e.Fianza__r.Name);
        }

        // Agregar relaciones múltiples
        for (Tech_Relacion__c rel : e.Relaciones_Tecnicas_Endoso__r) {
            if (rel.Tipo__c == 'Fianza' && rel.Fianza__r.Name != null) {
                if (!this.fianzas.contains(rel.Fianza__r.Name)) {
                    this.fianzas.add(rel.Fianza__r.Name);
                }
            }
        }

        this.estatus = 'Activo';
        this.estatusClass = 'airtable-badge-green';
    }
}