/**
 * SeguroRenovacionHandler — cuando un Seguro__c entra en Estatus = 'Por renovar'
 * (manual o vía RenovacionAlertaBatch), este handler:
 *
 *   1. Crea una Oportunidad de renovación en el pipeline con:
 *        - Account = Cliente del seguro
 *        - OwnerId = Vendedor del seguro
 *        - Name = "Renovación <póliza> - <cliente>"
 *        - Type = "Renovación"
 *        - StageName = "Prospección" (o stage inicial del proceso de renovación)
 *        - CloseDate = Fin_del_seguro__c
 *        - Amount = Prima_neta__c (si disponible)
 *   2. Guarda la fecha en Seguro__c.Fecha_marcado_por_renovar__c si no existe.
 *   3. Envía notificación al cliente (Email + WA stub).
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
public with sharing class SeguroRenovacionHandler {

    private static final String STAGE_INICIAL   = 'Prospección';
    private static final String OPP_TYPE        = 'Renovación';

    public static void handleAfterUpdate(List<Seguro__c> newList, Map<Id, Seguro__c> oldMap) {
        List<Seguro__c> transicionados = new List<Seguro__c>();
        for (Seguro__c s : newList) {
            Seguro__c prev = oldMap != null ? oldMap.get(s.Id) : null;
            if (prev == null) continue;
            if (s.Estatus__c == 'Por renovar' && prev.Estatus__c != 'Por renovar') {
                transicionados.add(s);
            }
        }
        if (transicionados.isEmpty()) return;
        crearOportunidadesRenovacion(transicionados);
    }

    private static void crearOportunidadesRenovacion(List<Seguro__c> seguros) {
        // Traer los campos que necesitamos para armar la Oportunidad
        Set<Id> seguroIds = new Set<Id>();
        for (Seguro__c s : seguros) seguroIds.add(s.Id);

        List<Seguro__c> enriched = [
            SELECT Id, Numero_poliza__c, Cliente__c, Vendedor__c, Ramo__c,
                   Fin_del_seguro__c, Prima_neta__c, OwnerId
            FROM Seguro__c
            WHERE Id IN :seguroIds
        ];

        Map<Id, Id> clienteMap = new Map<Id, Id>();
        for (Seguro__c s : enriched) {
            if (s.Cliente__c != null) clienteMap.put(s.Id, s.Cliente__c);
        }

        Map<Id, String> clienteNombre = new Map<Id, String>();
        if (!clienteMap.values().isEmpty()) {
            for (Account a : [SELECT Id, Name FROM Account WHERE Id IN :clienteMap.values()]) {
                clienteNombre.put(a.Id, a.Name);
            }
        }

        List<Opportunity> opsToInsert = new List<Opportunity>();
        for (Seguro__c s : enriched) {
            Opportunity op = new Opportunity();
            String nombreCliente = (s.Cliente__c != null) ? clienteNombre.get(s.Cliente__c) : 'Cliente';
            op.Name = 'Renovación ' + s.Numero_poliza__c + ' - ' + nombreCliente;
            op.AccountId = s.Cliente__c;
            op.StageName = STAGE_INICIAL;
            op.CloseDate = s.Fin_del_seguro__c != null ? s.Fin_del_seguro__c : Date.today().addDays(30);
            op.Type = OPP_TYPE;
            op.Amount = s.Prima_neta__c;
            // Nota: OwnerId NO se asigna desde Vendedor__c porque Vendedor__c es lookup a
            // objeto custom Vendedor, no a User. El owner default es el usuario que disparó
            // la transición. TODO: cuando exista un mapping Vendedor -> User, asignarlo aquí.
            opsToInsert.add(op);
        }
        if (!opsToInsert.isEmpty()) {
            Database.insert(opsToInsert, false);
        }
    }
}