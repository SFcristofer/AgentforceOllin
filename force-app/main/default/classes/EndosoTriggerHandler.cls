public class EndosoTriggerHandler {

    /**
     * Detecta cuando un endoso pasa a estado "Aprobado"
     * y dispara la aplicación del mismo.
     */
    public static void onEstadoCambiado(
        List<Endoso__c> newList,
        Map<Id, Endoso__c> oldMap
    ) {
        List<Endoso__c> endososAplicar = new List<Endoso__c>();

        for (Endoso__c e : newList) {
            Endoso__c old = oldMap.get(e.Id);
            if (e.Estado__c == 'Aprobado' && old.Estado__c != 'Aprobado') {
                endososAplicar.add(e);
            }
        }

        if (!endososAplicar.isEmpty()) {
            EndosoService.aplicarEndosos(endososAplicar);
        }
    }
}