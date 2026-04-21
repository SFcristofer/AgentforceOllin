/**
 * RemarketingCrossSellScheduler — semanal (lunes 08:00).
 * Para activar: System.schedule('Cross-Sell Semanal', '0 0 8 ? * MON', new RemarketingCrossSellScheduler());
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
public with sharing class RemarketingCrossSellScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new RemarketingCrossSellBatch(), 200);
    }
}