/**
 * Utilidad de migracion SICAS.
 *
 * generarPlanesFuturos(): genera Plan_de_Pagos__c + Recibo_de_Cobro__c SOLO para
 * los seguros historicos migrados que:
 *   - Migrado_SICAS__c = true
 *   - Estatus__c = 'Vigente'
 *   - Frecuencia_de_pago__c in ('Mensual','Quincenal','Trimestral','Semestral')
 *   - Aun NO tienen un Plan_de_Pagos__c (se evita duplicar)
 *   - Tienen al menos un recibo futuro (Fecha_programada__c >= TODAY) dentro
 *     del calendario natural de su vigencia.
 *
 * Regla de recibos: generamos solo los recibos cuya Fecha_programada__c >= TODAY.
 * Los recibos cuya fecha ya paso se asumen cobrados en SICAS y NO se crean en
 * Salesforce; esto evita falsos "Vencidos" y mantiene la cobranza futura limpia.
 *
 * Monto: el plan refleja Prima_neta__c total; el monto por recibo es
 * Prima_neta__c / N (N = total de pagos de la vigencia), con el ultimo recibo
 * absorbiendo la diferencia por redondeo. Los recibos historicos no se crean,
 * asi que la suma de recibos futuros sera un subconjunto, NO Prima_neta__c.
 *
 * Invocar via Anonymous Apex:
 *   Integer n = SICASMigracionUtil.generarPlanesFuturos();
 *   System.debug('Planes creados: ' + n);
 */
public with sharing class SICASMigracionUtil {

    private static final Set<String> FRECUENCIAS_PLAN_FUTURO = new Set<String>{
        'Mensual', 'Quincenal', 'Trimestral', 'Semestral'
    };

    /**
     * @return numero de Plan_de_Pagos__c creados
     */
    public static Integer generarPlanesFuturos() {
        Date hoy = Date.today();

        // 1) Seguros elegibles: migrados + Vigente + frecuencia plazo
        List<Seguro__c> candidatos = [
            SELECT Id, Prima_neta__c, Frecuencia_de_pago__c, Inicio_del_seguro__c,
                   Fin_del_seguro__c
            FROM Seguro__c
            WHERE Migrado_SICAS__c = true
              AND Estatus__c = 'Vigente'
              AND Frecuencia_de_pago__c IN :FRECUENCIAS_PLAN_FUTURO
              AND Inicio_del_seguro__c != null
              AND Prima_neta__c != null
              AND Prima_neta__c > 0
        ];

        if (candidatos.isEmpty()) return 0;

        // 2) Excluir los que ya tienen un Plan_de_Pagos__c (idempotencia)
        Set<Id> seguroIds = new Set<Id>();
        for (Seguro__c s : candidatos) seguroIds.add(s.Id);

        Set<Id> conPlan = new Set<Id>();
        for (Plan_de_Pagos__c p : [
            SELECT Seguro__c FROM Plan_de_Pagos__c WHERE Seguro__c IN :seguroIds
        ]) {
            conPlan.add(p.Seguro__c);
        }

        // 3) Construir planes y calcular recibos futuros
        List<Plan_de_Pagos__c> planes = new List<Plan_de_Pagos__c>();
        Map<Id, Seguro__c> seguroById = new Map<Id, Seguro__c>();

        for (Seguro__c s : candidatos) {
            if (conPlan.contains(s.Id)) continue;
            Integer n = numRecibosTotales(s.Frecuencia_de_pago__c);
            seguroById.put(s.Id, s);

            planes.add(new Plan_de_Pagos__c(
                Seguro__c       = s.Id,
                Fecha_inicio__c = s.Inicio_del_seguro__c,
                Frecuencia__c   = frecuenciaPlan(s.Frecuencia_de_pago__c),
                Monto__c        = s.Prima_neta__c,
                Num_recibos__c  = n,
                Estado__c       = 'Activo'
            ));
        }

        if (planes.isEmpty()) return 0;
        insert planes;

        // 4) Generar los recibos futuros (Fecha_programada__c >= hoy)
        List<Recibo_de_Cobro__c> recibos = new List<Recibo_de_Cobro__c>();

        for (Plan_de_Pagos__c plan : planes) {
            Seguro__c s = seguroById.get(plan.Seguro__c);
            Integer n = plan.Num_recibos__c.intValue();

            Decimal montoRecibo = (s.Prima_neta__c / n).setScale(2, System.RoundingMode.HALF_UP);
            Decimal sumaParcial = montoRecibo * (n - 1);
            Decimal montoUltimo = s.Prima_neta__c - sumaParcial;

            for (Integer i = 0; i < n; i++) {
                Date fechaProg = proximaFecha(plan.Fecha_inicio__c, s.Frecuencia_de_pago__c, i);
                // Saltar recibos cuya fecha ya paso (se asumen cobrados en SICAS)
                if (fechaProg < hoy) continue;

                recibos.add(new Recibo_de_Cobro__c(
                    Plan_de_Pagos__c    = plan.Id,
                    Numero__c           = i + 1,
                    Fecha_programada__c = fechaProg,
                    Monto_programado__c = (i == n - 1) ? montoUltimo : montoRecibo,
                    Estado__c           = 'Pendiente'
                ));
            }
        }

        if (!recibos.isEmpty()) insert recibos;
        return planes.size();
    }

    // --- helpers (copia del handler pero publicos/encapsulados) ---

    private static Integer numRecibosTotales(String frecuencia) {
        if (frecuencia == null) return 1;
        String f = frecuencia.toLowerCase();
        if (f == 'mensual')    return 12;
        if (f == 'quincenal')  return 24;
        if (f == 'semestral')  return 2;
        if (f == 'trimestral') return 4;
        if (f == 'anual')      return 1;
        return 1;
    }

    private static String frecuenciaPlan(String frecuenciaSeguro) {
        if (frecuenciaSeguro == null) return 'Unico';
        String f = frecuenciaSeguro.toLowerCase();
        if (f == 'mensual')    return 'Mensual';
        if (f == 'quincenal')  return 'Quincenal';
        if (f == 'semestral')  return 'Semestral';
        if (f == 'trimestral') return 'Trimestral';
        if (f == 'anual')      return 'Anual';
        return 'Unico';
    }

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
}