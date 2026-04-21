/**
 * TestDataFactory para el Modulo de Gestion.
 *
 * Centraliza la creacion de datos de prueba. Si Seguro__c tiene campos
 * requeridos adicionales en tu org, ajustalos en el metodo crearSeguro().
 */
@IsTest
public class TestDataFactoryGestion {

    /**
     * Crea un Seguro__c minimal para pruebas.
     * IMPORTANTE: Ajustar segun los campos requeridos reales del objeto Seguro__c
     * en tu org (ej. Cliente__c, Vigencia_inicio__c, Prima_total__c, etc.).
     */
    public static Seguro__c crearSeguro() {
        Seguro__c s = new Seguro__c();
        // Si Seguro__c tiene campos requeridos, ponerlos aqui.
        // Ejemplo:
        // s.Vigencia_inicio__c = Date.today();
        // s.Prima_total__c = 12000;
        insert s;
        return s;
    }

    public static Plan_de_Pagos__c crearPlan(Id seguroId, Decimal monto, Integer numRecibos) {
        Plan_de_Pagos__c p = new Plan_de_Pagos__c(
            Seguro__c = seguroId,
            Monto__c = monto,
            Num_recibos__c = numRecibos,
            Fecha_inicio__c = Date.today(),
            Frecuencia__c = 'Mensual',
            Estado__c = 'Activo'
        );
        insert p;
        return p;
    }

    public static List<Recibo_de_Cobro__c> crearRecibos(Id planId, Integer cantidad, Decimal montoCada) {
        List<Recibo_de_Cobro__c> recibos = new List<Recibo_de_Cobro__c>();
        for (Integer i = 0; i < cantidad; i++) {
            recibos.add(new Recibo_de_Cobro__c(
                Plan_de_Pagos__c = planId,
                Fecha_programada__c = Date.today().addMonths(i),
                Monto_programado__c = montoCada
                // Numero__c se auto-numera en before insert
                // Estado__c default Pendiente en before insert
            ));
        }
        insert recibos;
        return recibos;
    }
}