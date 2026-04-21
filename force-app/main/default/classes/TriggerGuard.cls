/**
 * Utility: TriggerGuard
 *
 * Evita recursion entre triggers que se llaman unos a otros
 * (ej: ReciboDeCobroTrigger -> update Plan -> PlanDePagosTrigger -> recalc Dias_mora).
 *
 * Uso:
 *   if (TriggerGuard.ejecutandose('MiBandera')) return;
 *   TriggerGuard.marcar('MiBandera');
 *
 * Las banderas son estaticas por transaccion (se resetean en cada request).
 */
public class TriggerGuard {
    private static Set<String> banderas = new Set<String>();

    public static Boolean ejecutandose(String nombre) {
        return banderas.contains(nombre);
    }

    public static void marcar(String nombre) {
        banderas.add(nombre);
    }

    public static void limpiar(String nombre) {
        banderas.remove(nombre);
    }

    public static void limpiarTodo() {
        banderas.clear();
    }
}