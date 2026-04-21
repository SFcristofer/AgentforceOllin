/**
 * @description Acción Invocable para Agentforce: Envía los datos finales para la emisión de la póliza.
 * Paso 4 y 5 de 6 en el flujo de seguros.
 */
public class Tech_SubmitInsuredData {

    public class PolicyInput {
        @InvocableVariable(label='ID de Cotización' required=true)
        public String quotationId;
        
        @InvocableVariable(label='RFC' description='Obligatorio para la mayoría de aseguradoras')
        public String rfc;
        
        @InvocableVariable(label='Número de Serie (VIN)' description='17 caracteres')
        public String vin;
        
        @InvocableVariable(label='Calle y Número')
        public String street;
        
        @InvocableVariable(label='Ocupación')
        public String occupation;

        @InvocableVariable(label='Estado Civil' description='C, D, S, U, V')
        public String maritalStatus;
        
        @InvocableVariable(label='Apellido Paterno' required=true)
        public String paternalSurname;
        
        @InvocableVariable(label='Apellido Materno' required=true)
        public String maternalSurname;

        @InvocableVariable(label='Nombres (Pila)' required=true)
        public String firstName;
    }

    public class PolicyOutput {
        @InvocableVariable(label='ID de Póliza')
        public String policyId;
        
        @InvocableVariable(label='URL de Pago')
        public String paymentUrl;
        
        @InvocableVariable(label='Monto Total' description='Formato moneda MXN')
        public Decimal totalAmount;

        @InvocableVariable(label='Error')
        public String errorMessage;
    }

    @InvocableMethod(label='Tech: Emitir Póliza y Pago' description='Envía los datos recolectados (RFC, VIN, etc.) para generar la póliza y el link de pago.')
    public static List<PolicyOutput> execute(List<PolicyInput> inputs) {
        List<PolicyOutput> outputs = new List<PolicyOutput>();
        
        for (PolicyInput input : inputs) {
            PolicyOutput out = new PolicyOutput();
            try {
                // Preparar el Mapa Dinámico para la API
                Map<String, Object> data = new Map<String, Object>();
                data.put('rfc', input.rfc);
                data.put('vin', input.vin);
                data.put('street', input.street);
                data.put('occupation', input.occupation);
                data.put('maritalStatus', input.maritalStatus);
                data.put('paternalSurname', input.paternalSurname);
                data.put('maternalSurname', input.maternalSurname);
                data.put('fullName', input.firstName); // La API lo pide como fullName pero solo con el nombre de pila.

                Tech_MueveteSeguroWrappers.PolicyResponse res = 
                    Tech_MueveteSeguroPolicyService.submitInsuredData(input.quotationId, data);
                
                out.policyId = res.policyId;
                out.paymentUrl = res.paymentUrl;
                out.totalAmount = res.amount;

            } catch (Exception e) {
                out.errorMessage = e.getMessage();
            }
            outputs.add(out);
        }
        return outputs;
    }
}