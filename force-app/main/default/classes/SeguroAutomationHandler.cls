/**
 * Handler central de automatizaciones sobre Seguro__c.
 *
 * Responsabilidades:
 *  - handleAfterInsert: genera Plan_de_Pagos__c + N Recibo_de_Cobro__c
 *    basado en Frecuencia_de_pago__c.
 *    Se omite cuando:
 *      * Tipo_originador__c == 'IA (Agentforce)' (venta digital al contado)
 *      * Migrado_SICAS__c == true (carga historica, los planes se generan
 *        a demanda via SICASMigracionUtil para producir solo recibos futuros)
 *  - handleAfterUpdate: cuando Estatus__c transita a 'Por renovar'
 *    crea una Opportunity de renovacion. Se omite cuando Migrado_SICAS__c == true
 *    (los historicos no re-disparan renovacion; el job nocturno actualiza el
 *    estatus y el proceso de renovacion se evalua en el siguiente ciclo anual).
 *
 * Invocado por SeguroAutomationTrigger.
 */
public with sharing class SeguroAutomationHandler {

    private static final Set<String> SKIP_ORIGINADOR = new Set<String>{
        'IA (Agentforce)'
    };

    /**
     * Mapeo Frecuencia de pago -> numero de recibos en una vigencia anual.
     * Mensual=12, Quincenal=24, Semestral=2, Trimestral=4, Contado=1.
     */
    @TestVisible
    private static Integer numRecibosPorFrecuencia(String frecuencia) {
        if (frecuencia == null) return 1;
        String f = frecuencia.toLowerCase();
        if (f == 'mensual')    return 12;
        if (f == 'quincenal')  return 24;
        if (f == 'semestral')  return 2;
        if (f == 'trimestral') return 4;
        if (f == 'anual')      return 1;
        if (f == 'contado')    return 1;
        return 1;
    }

    /**
     * Traduce la frecuencia del Seguro a la picklist de Plan_de_Pagos.Frecuencia__c.
     */
    @TestVisible
    private static String frecuenciaPlan(String frecuenciaSeguro) {
        if (frecuenciaSeguro == null) return 'Unico';
        String f = frecuenciaSeguro.toLowerCase();
        if (f == 'mensual')    return 'Mensual';
        if (f == 'quincenal')  return 'Quincenal';
        if (f == 'semestral')  return 'Semestral';
        if (f == 'trimestral') return 'Trimestral';
        if (f == 'anual')      return 'Anual';
        if (f == 'contado')    return 'Unico';
        return 'Unico';
    }

    /**
     * Avanza fechaBase N pasos segun frecuencia.
     */
    @TestVisible
    private static Date proximaFecha(Date fechaBase, String frecuencia, Integer n) {
        if (fechaBase == null || n == 0) return fechaBase;
        String f = frecuencia == null ? 'mensual' : frecuencia.toLowerCase();
        if (f == 'mensual')    return fechaBase.addMonths(n);
        if (f == 'quincenal')  return fechaBase.addDays(15 * n);
        if (f == 'semestral')  return fechaBase.addMonths(6 * n);
        if (f == 'trimestral') return fechaBase.addMonths(3 * n);
        if (f == 'anual')      return fechaBase.addYears(n);
        return fechaBase;
    }

    /**
     * Entry point para after insert: filtra seguros elegibles y genera planes.
     */
    public static void handleAfterInsert(List<Seguro__c> newList) {
        List<Seguro__c> eligibles = new List<Seguro__c>();
        for (Seguro__c s : newList) {
            // Saltar migracion historica SICAS.
            if (s.Migrado_SICAS__c == true) continue;
            if (s.Tipo_originador__c != null && SKIP_ORIGINADOR.contains(s.Tipo_originador__c)) {
                continue;
            }
            if (s.Prima_neta__c == null || s.Prima_neta__c <= 0) continue;
            if (s.Inicio_del_seguro__c == null) continue;
            eligibles.add(s);
        }
        if (eligibles.isEmpty()) return;
        generarPlanesYRecibos(eligibles);
    }

    /**
     * Entry point para after update: detecta transicion a 'Por renovar' y
     * genera Opportunity de renovacion.
     */
    public static void handleAfterUpdate(List<Seguro__c> newList, Map<Id, Seguro__c> oldMap) {
        List<Seguro__c> candidatos = new List<Seguro__c>();
        for (Seguro__c s : newList) {
            Seguro__c prev = oldMap.get(s.Id);
            if (prev == null) continue;
            // Saltar migracion historica SICAS (los Opportunity de renovacion se manejan
            // en el siguiente ciclo anual por el job nocturno cuando ya no son 'Migrados').
            if (s.Migrado_SICAS__c == true) continue;
            if (s.Estatus__c == 'Por renovar' && prev.Estatus__c != 'Por renovar') {
                candidatos.add(s);
            }
        }
        if (!candidatos.isEmpty()) {
            crearOportunidadesRenovacion(candidatos);
        }
    }

    /**
     * Crea Plan_de_Pagos__c + Recibo_de_Cobro__c (bulk-safe) para registros normales.
     * Genera todos los N recibos de la vigencia, cada uno Pendiente.
     */
    private static void generarPlanesYRecibos(List<Seguro__c> seguros) {
        List<Plan_de_Pagos__c> planes = new List<Plan_de_Pagos__c>();
        Map<Id, Seguro__c> seguroById = new Map<Id, Seguro__c>();

        for (Seguro__c s : seguros) {
            seguroById.put(s.Id, s);
            Integer n = numRecibosPorFrecuencia(s.Frecuencia_de_pago__c);
            Plan_de_Pagos__c plan = new Plan_de_Pagos__c(
                Seguro__c       = s.Id,
                Fecha_inicio__c = s.Inicio_del_seguro__c,
                Frecuencia__c   = frecuenciaPlan(s.Frecuencia_de_pago__c),
                Monto__c        = s.Prima_neta__c,
                Num_recibos__c  = n,
                Estado__c       = 'Activo'
            );
            planes.add(plan);
        }

        insert planes;

        List<Recibo_de_Cobro__c> recibos = new List<Recibo_de_Cobro__c>();
        for (Plan_de_Pagos__c plan : planes) {
            Seguro__c s = seguroById.get(plan.Seguro__c);
            Integer n = plan.Num_recibos__c.intValue();
            Decimal montoRecibo = (s.Prima_neta__c / n).setScale(2, System.RoundingMode.HALF_UP);
            Decimal sumaParcial = montoRecibo * (n - 1);
            Decimal montoUltimo = s.Prima_neta__c - sumaParcial;

            for (Integer i = 0; i < n; i++) {
                Recibo_de_Cobro__c r = new Recibo_de_Cobro__c(
                    Plan_de_Pagos__c    = plan.Id,
                    Numero__c           = i + 1,
                    Fecha_programada__c = proximaFecha(plan.Fecha_inicio__c, s.Frecuencia_de_pago__c, i),
                    Monto_programado__c = (i == n - 1) ? montoUltimo : montoRecibo,
                    Estado__c           = 'Pendiente'
                );
                recibos.add(r);
            }
        }
        if (!recibos.isEmpty()) {
            insert recibos;
        }
    }

    /**
     * Crea una Opportunity de renovacion por cada Seguro en 'Por renovar'.
     */
    private static void crearOportunidadesRenovacion(List<Seguro__c> seguros) {
        Set<Id> seguroIds = new Set<Id>();
        for (Seguro__c s : seguros) seguroIds.add(s.Id);

        Map<Id, Seguro__c> full = new Map<Id, Seguro__c>(
            [SELECT Id, Name, Cliente__c, Numero_poliza__c, Fin_del_seguro__c,
                    Prima_neta__c, Aseguradora__c, Vendedor__c, Ramo__c
             FROM Seguro__c WHERE Id IN :seguroIds]
        );

        Boolean hasSeguroLookup = Schema.getGlobalDescribe()
            .get('Opportunity').getDescribe().fields.getMap().containsKey('seguro_original__c');

        List<Opportunity> opps = new List<Opportunity>();
        for (Seguro__c s : seguros) {
            Seguro__c sf = full.get(s.Id);
            if (sf == null) continue;

            Opportunity op = new Opportunity();
            op.Name      = 'Renovacion ' +
                (sf.Numero_poliza__c != null ? sf.Numero_poliza__c : sf.Name);
            op.StageName = 'Prospecting';
            op.CloseDate = sf.Fin_del_seguro__c != null ? sf.Fin_del_seguro__c : Date.today().addDays(30);
            if (sf.Cliente__c != null) op.AccountId = sf.Cliente__c;
            op.Amount    = sf.Prima_neta__c;
            op.Type      = 'Renovacion';
            if (hasSeguroLookup) {
                op.put('Seguro_original__c', sf.Id);
            }
            opps.add(op);
        }
        if (!opps.isEmpty()) {
            insert opps;
        }
    }
}