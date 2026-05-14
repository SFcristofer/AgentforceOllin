/**
 * @description Acción Invocable profesional: Obtiene los campos requeridos y asegura la selección del plan.
 */
public class Tech_ProcessRequiredFields {

    public class FieldInput {
        @InvocableVariable(label='ID de Cotizacion' required=true)
        public String quotationId;

        @InvocableVariable(label='Aseguradora Seleccionada' required=true)
        public String insurerName;
    }

    public class FieldOutput {
        @InvocableVariable(label='Campos a Preguntar')
        public List<Tech_MueveteSeguroWrappers.RequiredField> requiredFields;

        @InvocableVariable(label='Resumen de Campos')
        public String fieldSummary;
    }

    @InvocableMethod(label='Tech: Procesar Campos de Aseguradora' description='Confirma la aseguradora elegida y recupera los campos obligatorios para la emisión.')
    public static List<FieldOutput> execute(List<FieldInput> inputs) {
        List<FieldOutput> outputs = new List<FieldOutput>();
        for (FieldInput input : inputs) {
            FieldOutput out = new FieldOutput();
            try {
                // PASO TÉCNICO VITAL: Confirmar la selección en la API antes de pedir los campos.
                // Esto evita el error "Debe seleccionar un plan antes de crear la póliza".
                List<Tech_MueveteSeguroWrappers.RequiredField> fields = 
                    Tech_MueveteSeguroPlanService.selectPlan(input.quotationId, input.insurerName);

                out.requiredFields = fields;

                List<String> labels = new List<String>();
                for (Tech_MueveteSeguroWrappers.RequiredField f : fields) {
                    labels.add(f.description);
                }
                out.fieldSummary = 'Para emitir con ' + input.insurerName + ' se requiere: ' + String.join(labels, ', ');
            } catch (Exception e) {
                out.fieldSummary = 'Error al recuperar campos: ' + e.getMessage();
            }
            outputs.add(out);
        }
        return outputs;
    }
}