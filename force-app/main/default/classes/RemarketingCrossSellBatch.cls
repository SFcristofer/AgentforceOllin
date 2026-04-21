/**
 * RemarketingCrossSellBatch — Scheduled Batch semanal.
 *
 * Identifica clientes (Account) que tienen exactamente 1 seguro vigente y
 * crea Task al Vendedor para ofrecer otra línea.
 * Se ejecuta semanalmente para no inundar al vendedor.
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
public with sharing class RemarketingCrossSellBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Integer totalTasksCrossSell = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Clientes con un solo seguro vigente (el vendedor es lookup a objeto custom,
        // no a User; por eso no lo usamos como OwnerId de la Task).
        return Database.getQueryLocator([
            SELECT Id, Cliente__c, Vendedor__c, Numero_poliza__c, Ramo__c
            FROM Seguro__c
            WHERE Estatus__c = 'Vigente'
              AND Cliente__c != null
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Seguro__c> scope) {
        // Contar seguros vigentes por Cliente
        Map<Id, Integer> polizasPorCliente = new Map<Id, Integer>();
        Map<Id, Seguro__c> primerSeguroPorCliente = new Map<Id, Seguro__c>();

        for (Seguro__c s : scope) {
            Integer cnt = polizasPorCliente.containsKey(s.Cliente__c)
                ? polizasPorCliente.get(s.Cliente__c) + 1
                : 1;
            polizasPorCliente.put(s.Cliente__c, cnt);
            if (!primerSeguroPorCliente.containsKey(s.Cliente__c)) {
                primerSeguroPorCliente.put(s.Cliente__c, s);
            }
        }

        // Evitar duplicar: buscar si ya existe Task cross-sell abierta para el cliente
        Set<Id> cliIds = polizasPorCliente.keySet();
        Set<Id> cliConTaskAbierta = new Set<Id>();
        for (Task t : [
            SELECT WhatId FROM Task
            WHERE WhatId IN :cliIds
              AND Subject LIKE 'Cross-sell oportunidad%'
              AND IsClosed = false
        ]) {
            cliConTaskAbierta.add(t.WhatId);
        }

        List<Task> tasks = new List<Task>();
        for (Id cli : polizasPorCliente.keySet()) {
            if (polizasPorCliente.get(cli) != 1) continue;
            if (cliConTaskAbierta.contains(cli)) continue;
            Seguro__c s = primerSeguroPorCliente.get(cli);
            if (s == null) continue;

            Task t = new Task();
            t.Subject = 'Cross-sell oportunidad — cliente solo con ' + s.Ramo__c;
            t.Priority = 'Normal';
            t.Status = 'Not Started';
            t.ActivityDate = Date.today().addDays(3);
            t.WhatId = cli;
            // OwnerId: sin asignar (default = running user). Vendedor__c es lookup custom,
            // no User, por lo que no se puede usar directo como OwnerId. TODO: mapear
            // Vendedor -> User cuando exista el bridge.
            t.Description = 'Este cliente solo tiene 1 seguro activo (' + s.Ramo__c
                + ', póliza ' + s.Numero_poliza__c
                + '). Ofrécele otra línea: GMM, Vida, Daños, RC, Fianzas.';
            tasks.add(t);
            totalTasksCrossSell++;
        }

        if (!tasks.isEmpty()) {
            Database.insert(tasks, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'RemarketingCrossSellBatch finished. CrossSellTasks=' + totalTasksCrossSell);
    }
}