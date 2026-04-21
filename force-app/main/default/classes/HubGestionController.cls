/**
 * HubGestionController - v6.1
 * ---------------------------------------------------------------------------
 * Controller del Hub de Gestion (LWC: cognoHubGestion).
 *
 * Cambios respecto a v4.1:
 *   - Fix critico de valores de picklist Recibo_de_Cobro__c.Estado__c:
 *     'Programado' -> 'Pendiente' (valor real del picklist restringido)
 *     'Cobrado'    -> 'Pagado'    (valor real del picklist restringido)
 *     Bug latente que dejaba 3 KPIs en cero (Por cobrar, Pagado este mes,
 *     Pendiente del mes). Validado vs datos reales del sandbox: 288
 *     Pendientes por $274,184 y 28 Pendientes del mes por $23,454 que no
 *     se estaban contando. Alineado con los valores reales:
 *     Pendiente / Vencido / Parcial / Pagado / Cancelado / Reembolsado.
 *
 * Cambios respecto a v4 (mantenidos):
 *   - Dias mora y dias para vencer siempre positivos.
 *   - diasAtrasoTexto en SeguroRow ("hace N dias") para atrasadas.
 *   - Ramo en recibos vencidos via Plan_de_Pagos__r.Seguro__r.Ramo__c.
 *   - Renovaciones en 3 buckets mensuales.
 *   - marcarNoRenovada(seguroId, motivo) para cerrar ciclo.
 *
 * Autor: Ollin Proteccion - 2026-04-19 (v6.1)
 * ---------------------------------------------------------------------------
 */
public with sharing class HubGestionController {

    /* =====================================================================
     *  WRAPPERS
     * ===================================================================== */

    public class HubData {
        @AuraEnabled public KpiBlock kpis;
        @AuraEnabled public List<ReciboRow> recibosVencidos;
        @AuraEnabled public RenovacionesBlock renovaciones;
        @AuraEnabled public List<PicklistOption> motivosNoRenovacion;
    }

    public class KpiBlock {
        @AuraEnabled public Integer vencidosCount;
        @AuraEnabled public Decimal vencidosAmount;
        @AuraEnabled public Integer porCobrarCount;
        @AuraEnabled public Decimal porCobrarAmount;
        @AuraEnabled public Integer pagadoMesCount;
        @AuraEnabled public Decimal pagadoMesAmount;
        @AuraEnabled public Integer atrasadasCount;
        @AuraEnabled public Decimal atrasadasAmount;
        @AuraEnabled public Integer renovacionesMesActualCount;
        @AuraEnabled public Decimal renovacionesMesActualAmount;
        @AuraEnabled public Integer renovacionesMesSiguienteCount;
        @AuraEnabled public Decimal renovacionesMesSiguienteAmount;
        @AuraEnabled public Integer pendienteMesCount;
        @AuraEnabled public Decimal pendienteMesAmount;
    }

    public class ReciboRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String numero;
        @AuraEnabled public String poliza;
        @AuraEnabled public String cliente;
        @AuraEnabled public String ramo;
        @AuraEnabled public Date fechaProgramada;
        @AuraEnabled public Integer diasMora;
        @AuraEnabled public Decimal monto;
        @AuraEnabled public String semaforo;
    }

    public class RenovacionesBlock {
        @AuraEnabled public List<SeguroRow> atrasadas;
        @AuraEnabled public List<SeguroRow> mesActual;
        @AuraEnabled public List<SeguroRow> mesSiguiente;
    }

    public class SeguroRow {
        @AuraEnabled public Id id;
        @AuraEnabled public String numeroPoliza;
        @AuraEnabled public String cliente;
        @AuraEnabled public String ramo;
        @AuraEnabled public Date finVigencia;
        @AuraEnabled public Integer diasParaVencer;
        @AuraEnabled public String diasAtrasoTexto;
        @AuraEnabled public Decimal primaTotal;
    }

    public class PicklistOption {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
    }

    /* =====================================================================
     *  CONSTANTES
     * ===================================================================== */

    private static final Set<String> ESTATUS_RENOVABLES = new Set<String>{
        'Vigente', 'Por renovar'
    };

    /* =====================================================================
     *  MÉTODO PRINCIPAL
     * ===================================================================== */

    @AuraEnabled(cacheable=true)
    public static HubData getHubData() {
        HubData data = new HubData();
        data.kpis = new KpiBlock();
        data.renovaciones = new RenovacionesBlock();
        data.renovaciones.atrasadas = new List<SeguroRow>();
        data.renovaciones.mesActual = new List<SeguroRow>();
        data.renovaciones.mesSiguiente = new List<SeguroRow>();
        data.recibosVencidos = new List<ReciboRow>();
        data.motivosNoRenovacion = new List<PicklistOption>();

        Date today = Date.today();
        Date primerDiaMes = Date.newInstance(today.year(), today.month(), 1);
        Date primerDiaMesSig = primerDiaMes.addMonths(1);
        Date primerDiaMesSigSig = primerDiaMes.addMonths(2);

        /* ---------- KPIs de cobranza ---------- */
        // Vencidos
        AggregateResult[] arVencidos = [
            SELECT COUNT(Id) c, SUM(Monto_programado__c) s
            FROM Recibo_de_Cobro__c
            WHERE Estado__c = 'Vencido'
        ];
        data.kpis.vencidosCount = (Integer) arVencidos[0].get('c');
        data.kpis.vencidosAmount = (Decimal) arVencidos[0].get('s');
        if (data.kpis.vencidosAmount == null) data.kpis.vencidosAmount = 0;

        // Por cobrar (pendiente con fecha futura)
        AggregateResult[] arPorCobrar = [
            SELECT COUNT(Id) c, SUM(Monto_programado__c) s
            FROM Recibo_de_Cobro__c
            WHERE Estado__c = 'Pendiente'
            AND Fecha_programada__c >= :today
        ];
        data.kpis.porCobrarCount = (Integer) arPorCobrar[0].get('c');
        data.kpis.porCobrarAmount = (Decimal) arPorCobrar[0].get('s');
        if (data.kpis.porCobrarAmount == null) data.kpis.porCobrarAmount = 0;

        // Pagado este mes
        AggregateResult[] arPagadoMes = [
            SELECT COUNT(Id) c, SUM(Monto_pagado__c) s
            FROM Recibo_de_Cobro__c
            WHERE Estado__c = 'Pagado'
            AND Fecha_pago__c >= :primerDiaMes
            AND Fecha_pago__c < :primerDiaMesSig
        ];
        data.kpis.pagadoMesCount = (Integer) arPagadoMes[0].get('c');
        data.kpis.pagadoMesAmount = (Decimal) arPagadoMes[0].get('s');
        if (data.kpis.pagadoMesAmount == null) data.kpis.pagadoMesAmount = 0;

        // Pendiente del mes (pendiente que vence este mes)
        AggregateResult[] arPendienteMes = [
            SELECT COUNT(Id) c, SUM(Monto_programado__c) s
            FROM Recibo_de_Cobro__c
            WHERE Estado__c = 'Pendiente'
            AND Fecha_programada__c >= :primerDiaMes
            AND Fecha_programada__c < :primerDiaMesSig
        ];
        data.kpis.pendienteMesCount = (Integer) arPendienteMes[0].get('c');
        data.kpis.pendienteMesAmount = (Decimal) arPendienteMes[0].get('s');
        if (data.kpis.pendienteMesAmount == null) data.kpis.pendienteMesAmount = 0;

        /* ---------- Renovaciones: 3 buckets mensuales ---------- */
        List<Seguro__c> segsRenov = [
            SELECT Id, Numero_poliza__c, Ramo__c, Fin_del_seguro__c,
                   Dias_para_vencer__c, Prima_neta__c,
                   Cliente__r.Name, Estatus__c
            FROM Seguro__c
            WHERE Estatus__c IN :ESTATUS_RENOVABLES
            AND Fin_del_seguro__c < :primerDiaMesSigSig
            ORDER BY Fin_del_seguro__c ASC
            LIMIT 500
        ];

        Decimal montoAtrasadas = 0;
        Decimal montoMesActual = 0;
        Decimal montoMesSig = 0;

        for (Seguro__c s : segsRenov) {
            SeguroRow row = new SeguroRow();
            row.id = s.Id;
            row.numeroPoliza = s.Numero_poliza__c;
            row.cliente = s.Cliente__r != null ? s.Cliente__r.Name : '';
            row.ramo = s.Ramo__c;
            row.finVigencia = s.Fin_del_seguro__c;
            Integer diasRaw = s.Dias_para_vencer__c != null ? s.Dias_para_vencer__c.intValue() : null;
            row.diasParaVencer = diasRaw;
            row.primaTotal = s.Prima_neta__c != null ? s.Prima_neta__c : 0;

            if (s.Fin_del_seguro__c < today) {
                // Atrasada: calcular días de atraso como positivo y texto amigable
                Integer atraso = diasRaw != null ? Math.abs(diasRaw) : today.daysBetween(s.Fin_del_seguro__c) * -1;
                row.diasAtrasoTexto = 'hace ' + atraso + (atraso == 1 ? ' día' : ' días');
                row.diasParaVencer = -atraso;
                data.renovaciones.atrasadas.add(row);
                montoAtrasadas += row.primaTotal;
            } else if (s.Fin_del_seguro__c < primerDiaMesSig) {
                // Mes actual: días restantes positivos
                row.diasParaVencer = diasRaw != null ? Math.abs(diasRaw) : today.daysBetween(s.Fin_del_seguro__c);
                row.diasAtrasoTexto = null;
                data.renovaciones.mesActual.add(row);
                montoMesActual += row.primaTotal;
            } else {
                row.diasParaVencer = diasRaw != null ? Math.abs(diasRaw) : today.daysBetween(s.Fin_del_seguro__c);
                row.diasAtrasoTexto = null;
                data.renovaciones.mesSiguiente.add(row);
                montoMesSig += row.primaTotal;
            }
        }

        data.kpis.atrasadasCount = data.renovaciones.atrasadas.size();
        data.kpis.atrasadasAmount = montoAtrasadas;
        data.kpis.renovacionesMesActualCount = data.renovaciones.mesActual.size();
        data.kpis.renovacionesMesActualAmount = montoMesActual;
        data.kpis.renovacionesMesSiguienteCount = data.renovaciones.mesSiguiente.size();
        data.kpis.renovacionesMesSiguienteAmount = montoMesSig;

        /* ---------- Tabla de recibos vencidos ----------
         * Usamos los campos denormalizados de Recibo_de_Cobro__c
         * (Poliza_numero__c, Cliente_nombre__c) + navegación Plan_de_Pagos__r
         * → Seguro__r.Ramo__c para el ramo (schema real confirmado vía
         * describe: en Plan_de_Pagos__c el lookup a Seguro es `Seguro__c`,
         * NO `Poliza__c`).
         */
        List<Recibo_de_Cobro__c> vencidos = [
            SELECT Id, Numero__c, Fecha_programada__c, Dias_mora__c,
                   Monto_programado__c,
                   Poliza_numero__c, Cliente_nombre__c, Semaforo_cobranza__c,
                   Plan_de_Pagos__r.Seguro__r.Ramo__c
            FROM Recibo_de_Cobro__c
            WHERE Estado__c = 'Vencido'
            ORDER BY Dias_mora__c DESC NULLS LAST
            LIMIT 200
        ];

        for (Recibo_de_Cobro__c r : vencidos) {
            ReciboRow row = new ReciboRow();
            row.id = r.Id;
            row.numero = r.Numero__c != null ? String.valueOf(r.Numero__c) : null;
            row.fechaProgramada = r.Fecha_programada__c;
            // Días mora siempre en positivo para UI
            row.diasMora = r.Dias_mora__c != null ? Math.abs(r.Dias_mora__c.intValue()) : 0;
            row.monto = r.Monto_programado__c != null ? r.Monto_programado__c : 0;
            row.poliza = r.Poliza_numero__c;
            row.cliente = r.Cliente_nombre__c;
            // Ramo vía Plan_de_Pagos__r.Seguro__r.Ramo__c (con guards)
            String ramoVal = null;
            if (r.Plan_de_Pagos__r != null && r.Plan_de_Pagos__r.Seguro__r != null) {
                ramoVal = r.Plan_de_Pagos__r.Seguro__r.Ramo__c;
            }
            row.ramo = ramoVal != null ? ramoVal : '';
            // Semáforo: rojo >30d, amarillo 8-30d, naranja 1-7d
            if (row.diasMora > 30)      row.semaforo = 'rojo';
            else if (row.diasMora > 7)  row.semaforo = 'amarillo';
            else                         row.semaforo = 'naranja';
            data.recibosVencidos.add(row);
        }

        /* ---------- Motivos de no renovación (picklist) ---------- */
        Schema.DescribeFieldResult motivoDesc = Seguro__c.Motivo_No_Renovacion__c.getDescribe();
        for (Schema.PicklistEntry pe : motivoDesc.getPicklistValues()) {
            if (pe.isActive()) {
                PicklistOption opt = new PicklistOption();
                opt.label = pe.getLabel();
                opt.value = pe.getValue();
                data.motivosNoRenovacion.add(opt);
            }
        }

        return data;
    }

    /* =====================================================================
     *  MARCAR NO RENOVADA (cierre de ciclo)
     * ===================================================================== */

    @AuraEnabled
    public static void marcarNoRenovada(Id seguroId, String motivo) {
        if (seguroId == null) {
            throw new AuraHandledException('Seguro requerido.');
        }
        if (String.isBlank(motivo)) {
            throw new AuraHandledException('Motivo requerido.');
        }
        // Validar que el motivo sea un valor activo del picklist
        Set<String> valoresValidos = new Set<String>();
        for (Schema.PicklistEntry pe : Seguro__c.Motivo_No_Renovacion__c.getDescribe().getPicklistValues()) {
            if (pe.isActive()) valoresValidos.add(pe.getValue());
        }
        if (!valoresValidos.contains(motivo)) {
            throw new AuraHandledException('Motivo inválido.');
        }

        Seguro__c s = [
            SELECT Id, Estatus__c
            FROM Seguro__c
            WHERE Id = :seguroId
            LIMIT 1
        ];
        s.Estatus__c = 'No renovada';
        s.Motivo_No_Renovacion__c = motivo;
        update s;
    }
}