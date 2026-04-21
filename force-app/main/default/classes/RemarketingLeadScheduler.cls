/**
 * RemarketingLeadScheduler — corre RemarketingLeadBatch diariamente.
 * Para activar: System.schedule('Remarketing Leads Diario', '0 0 10 * * ?', new RemarketingLeadScheduler());
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
public with sharing class RemarketingLeadScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new RemarketingLeadBatch(), 200);
    }
}