/**
 * CobranzaReminderScheduler — corre CobranzaReminderBatch diariamente.
 * Para activar: System.schedule('Cobranza Recordatorios Diario', '0 0 9 * * ?', new CobranzaReminderScheduler());
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
public with sharing class CobranzaReminderScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CobranzaReminderBatch(), 100);
    }
}