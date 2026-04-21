/**
 * @description Acción Invocable para Agentforce: Procesa los campos dinámicos requeridos por cada aseguradora.
 * Paso 3 de 6 en el flujo de seguros.
 */
public class Tech_ProcessRequiredFields {

    public class FieldInput {
        @InvocableVariable(label='ID de Cotización' required=true)
        public String quotationId;
        
        @InvocableVariable(label='Aseguradora Seleccionada' required=true)
        public String insurerName;
    }

    public class FieldOutput {
        @InvocableVariable(label='Campos a Preguntar')
        public List<Tech_MueveteSeguroWrappers.RequiredField> requiredFields;
        
        @InvocableVariable(label='Resumen de Campos' description='Un texto para que el agente sepa qué pedir')
        public String fieldSummary;

        @InvocableVariable(label='Error')
        public String errorMessage;
    }

    @InvocableMethod(label='Tech: Procesar Campos de Aseguradora' description='Obtiene la lista dinámica de campos (RFC, VIN, etc.) necesarios para la aseguradora elegida.')
    public static List<FieldOutput> execute(List<FieldInput> inputs) {
        List<FieldOutput> outputs = new List<FieldOutput>();
        
        for (FieldInput input : inputs) {
            FieldOutput out = new FieldOutput();
            try {
                List<Tech_MueveteSeguroWrappers.RequiredField> fields = 
                    Tech_MueveteSeguroPlanService.selectPlan(input.quotationId, input.insurerName);
                
                out.requiredFields = fields;
                
                // Generar un resumen amigable para el Agente
                List<String> fieldNames = new List<String>();
                for (Tech_MueveteSeguroWrappers.RequiredField f : fields) {
                    fieldNames.add(f.description + (f.required ? ' (Obligatorio)' : ''));
                }
                out.fieldSummary = 'Para cotizar con ' + input.insurerName + ' necesito: ' + String.join(fieldNames, ', ');
                
            } catch (Exception e) {
                out.errorMessage = e.getMessage();
            }
            outputs.add(out);
        }
        return outputs;
    }
}