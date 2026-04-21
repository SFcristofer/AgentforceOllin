/**
 * RenovacionAlertaBatch — Scheduled Batch diario.
 *
 * Evalúa Seguros vigentes y los mueve a Estatus = 'Por renovar' cuando el umbral
 * por ramo se cumple:
 *    - Auto        : 45 días antes del fin de vigencia
 *    - GMM         : 60 días
 *    - Vida / PPR  : 90 días
 *    - Daños / RC  : 30 días
 *
 * Además, aplica cadencia post-alerta (7/30/45 días desde que entró en "Por renovar")
 * creando Tasks al Vendedor (y se delega el envío WA/Email a CobranzaMessaging).
 *
 * El Record-Triggered (SeguroRenovacionTrigger) hace lo que sucede AL MOMENTO
 * de entrar en "Por renovar" (crear Oportunidad). Este batch solo empuja el cambio
 * de estatus para que el trigger se dispare.
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
public with sharing class RenovacionAlertaBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Integer totalMarcadosPorRenovar = 0;
    public Integer totalTasksCadencia       = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Ramo__c, Estatus__c, Dias_para_vencer__c,
                   Fin_del_seguro__c, Numero_poliza__c, Cliente__c, Vendedor__c,
                   Fecha_marcado_por_renovar__c
            FROM Seguro__c
            WHERE Estatus__c IN ('Vigente', 'Por renovar')
              AND Fin_del_seguro__c >= :Date.today()
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Seguro__c> scope) {
        List<Seguro__c> toUpdate = new List<Seguro__c>();
        List<Task> cadenciaTasks = new List<Task>();
        Date today = Date.today();

        for (Seguro__c s : scope) {
            Integer umbral = umbralPorRamo(s.Ramo__c);
            Integer dias   = s.Dias_para_vencer__c != null ? s.Dias_para_vencer__c.intValue() : null;
            if (dias == null) continue;

            // 1) Si aún está Vigente y ya dentro del umbral, moverlo a Por renovar
            if (s.Estatus__c == 'Vigente' && dias <= umbral) {
                s.Estatus__c = 'Por renovar';
                if (s.Fecha_marcado_por_renovar__c == null) {
                    s.Fecha_marcado_por_renovar__c = today;
                }
                toUpdate.add(s);
                totalMarcadosPorRenovar++;
                continue;
            }

            // 2) Si ya está Por renovar, aplicar cadencia 7/30/45 días desde marcado
            if (s.Estatus__c == 'Por renovar' && s.Fecha_marcado_por_renovar__c != null) {
                Integer diasDesdeMarcado = s.Fecha_marcado_por_renovar__c.daysBetween(today);
                if (diasDesdeMarcado == 7 || diasDesdeMarcado == 30 || diasDesdeMarcado == 45) {
                    Task t = new Task();
                    t.Subject = 'Renovación cadencia ' + diasDesdeMarcado + 'd — ' + s.Numero_poliza__c;
                    t.Priority = (diasDesdeMarcado >= 30) ? 'High' : 'Normal';
                    t.Status = 'Not Started';
                    t.ActivityDate = today;
                    t.WhatId = s.Id;
                    // OwnerId default = running user. Vendedor__c es lookup custom (no User).
                    t.Description = 'Seguimiento de renovación — póliza ' + s.Numero_poliza__c
                        + '. Vence ' + String.valueOf(s.Fin_del_seguro__c)
                        + '. Ramo ' + s.Ramo__c + '. ' + dias + ' días para vencer.';
                    cadenciaTasks.add(t);
                    totalTasksCadencia++;
                }
            }
        }

        if (!toUpdate.isEmpty()) {
            Database.update(toUpdate, false);
        }
        if (!cadenciaTasks.isEmpty()) {
            Database.insert(cadenciaTasks, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'RenovacionAlertaBatch finished. PorRenovar=' + totalMarcadosPorRenovar
            + ' TasksCadencia=' + totalTasksCadencia);
    }

    /**
     * Umbrales por ramo (días antes del vencimiento).
     * Fallback conservador: 30d.
     */
    @TestVisible
    private static Integer umbralPorRamo(String ramo) {
        if (String.isBlank(ramo)) return 30;
        String r = ramo.toLowerCase();
        if (r == 'auto' || r == 'autos') return 45;
        if (r == 'gmm' || r.contains('gastos med')) return 60;
        if (r == 'vida' || r == 'ppr' || r == 'vida/ppr') return 90;
        if (r == 'daños' || r == 'danos' || r == 'rc') return 30;
        return 30;
    }
}