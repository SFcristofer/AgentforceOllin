/**
 * @description Acción Invocable profesional: Obtiene los campos requeridos por la aseguradora.
 * Mantiene la interfaz limpia y delega la gestión de memoria al Agente de Agentforce.
 */
public class Tech_ProcessRequiredFields {

    public class FieldInput {
        @InvocableVariable(label='ID de Cotizacion' description='Identificador unico de la cotizacion.' required=true)
        public String quotationId;
        
        @InvocableVariable(label='Aseguradora Seleccionada' description='Nombre de la aseguradora (ej. ANA, HDI).' required=true)
        public String insurerName;
    }

    public class FieldOutput {
        @InvocableVariable(label='Campos a Preguntar' description='Lista tecnica de metadatos de los campos requeridos.')
        public List<Tech_MueveteSeguroWrappers.RequiredField> requiredFields;
        
        @InvocableVariable(label='Resumen de Campos' description='Lista amigable de campos requeridos para mostrar al usuario.')
        public String fieldSummary;
    }

    @InvocableMethod(label='Tech: Procesar Campos de Aseguradora' description='Consulta la API de Ollin para identificar que datos adicionales faltan para la emision.')
    public static List<FieldOutput> execute(List<FieldInput> inputs) {
        List<FieldOutput> outputs = new List<FieldOutput>();
        for (FieldInput input : inputs) {
            FieldOutput out = new FieldOutput();
            try {
                List<Tech_MueveteSeguroWrappers.RequiredField> fields = Tech_MueveteSeguroPlanService.selectPlan(input.quotationId, input.insurerName);
                out.requiredFields = fields;
                
                List<String> labels = new List<String>();
                for (Tech_MueveteSeguroWrappers.RequiredField f : fields) {
                    labels.add(f.description);
                }
                out.fieldSummary = 'Para emitir con ' + input.insurerName + ' se requiere: ' + String.join(labels, ', ');
            } catch (Exception e) {
                // Manejo de error
            }
            outputs.add(out);
        }
        return outputs;
    }
}