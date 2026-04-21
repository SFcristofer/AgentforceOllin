/**
 * RenovacionAlertaScheduler — corre RenovacionAlertaBatch diariamente a las 06:30.
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
public with sharing class RenovacionAlertaScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new RenovacionAlertaBatch(), 200);
    }
}