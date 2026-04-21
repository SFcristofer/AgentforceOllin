/**
 * CobranzaVencidoScheduler — corre CobranzaVencidoBatch diariamente.
 * Para activar: System.schedule('Cobranza Vencidos Diario', '0 0 6 * * ?', new CobranzaVencidoScheduler());
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
public with sharing class CobranzaVencidoScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new CobranzaVencidoBatch(), 200);
    }
}