/**
 * RemarketingLeadBatch — Scheduled Batch diario.
 *
 * Cadencia de remarketing para leads perdidos.
 * Touchpoints a 7 / 30 / 60 / 90 días post-cierre:
 *   7d  → oferta misma línea (precio ajustado o info adicional)
 *   30d → survey / objeción
 *   60d → cross-sell a otra línea
 *   90d → último intento + handoff a Agentforce
 *
 * En cada touchpoint: crea Task + dispara email + stub WA.
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
public with sharing class RemarketingLeadBatch implements Database.Batchable<SObject>, Database.Stateful {

    public Integer totalTouchpoints = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Leads perdidos. Usamos LastModifiedDate como proxy de "fecha de cierre".
        // Nota: si Ollin crea un campo custom `Fecha_cierre_lead__c`, reemplazar aquí.
        Datetime cutoff = Datetime.now().addDays(-91);
        return Database.getQueryLocator([
            SELECT Id, Name, Email, MobilePhone, OwnerId, Status, LastModifiedDate
            FROM Lead
            WHERE IsConverted = false
              AND Status = 'Perdido'
              AND LastModifiedDate >= :cutoff
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Lead> scope) {
        List<Task> tasks = new List<Task>();
        Date today = Date.today();

        for (Lead l : scope) {
            Integer diasDesdeCierre = (l.LastModifiedDate != null)
                ? l.LastModifiedDate.date().daysBetween(today)
                : 0;

            String accion;
            String priority = 'Normal';
            if (diasDesdeCierre == 7)  accion = 'Touchpoint 7d — oferta de reactivación';
            else if (diasDesdeCierre == 30) accion = 'Touchpoint 30d — survey de objeciones';
            else if (diasDesdeCierre == 60) accion = 'Touchpoint 60d — cross-sell a otra línea';
            else if (diasDesdeCierre == 90) { accion = 'Touchpoint 90d — handoff Agentforce'; priority = 'High'; }
            else continue;

            Task t = new Task();
            t.Subject = 'Remarketing ' + accion + ' — ' + l.Name;
            t.Priority = priority;
            t.Status = 'Not Started';
            t.ActivityDate = today;
            t.WhoId = l.Id;
            t.OwnerId = l.OwnerId;
            t.Description = 'Acción automática de cadencia post-cierre para lead ' + l.Name
                + ' (' + diasDesdeCierre + 'd desde que se marcó Perdido).';
            tasks.add(t);

            // Mensajería
            if (String.isNotBlank(l.Email)) {
                CobranzaMessaging.sendEmail(null, l.Email,
                    'Te extrañamos — ' + accion,
                    '<p>Hola ' + l.Name + ',</p><p>' + accion
                    + '</p><p>Contáctanos cuando gustes. — Ollin Protección</p>');
            }
            CobranzaMessaging.sendWhatsApp(l.MobilePhone,
                'Hola ' + l.Name + '. ' + accion + '. — Ollin Protección');

            totalTouchpoints++;
        }

        if (!tasks.isEmpty()) {
            Database.insert(tasks, false);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO,
            'RemarketingLeadBatch finished. Touchpoints=' + totalTouchpoints);
    }
}