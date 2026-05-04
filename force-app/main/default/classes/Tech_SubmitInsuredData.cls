/**
 * @description Acción Invocable mejorada y escalable para Agentforce.
 */
public class Tech_SubmitInsuredData {

    public class PolicyInput {
        @InvocableVariable(label='ID de Cotizacion' required=true)
        public String quotationId;
        
        @InvocableVariable(label='RFC')
        public String rfc;
        
        @InvocableVariable(label='CURP')
        public String curp;
        
        @InvocableVariable(label='Numero de Serie (VIN)')
        public String vin;
        
        @InvocableVariable(label='Calle y Numero')
        public String street;
        
        @InvocableVariable(label='Ocupacion')
        public String occupation;

        @InvocableVariable(label='Estado Civil')
        public String maritalStatus;
        
        @InvocableVariable(label='Apellido Paterno' required=true)
        public String paternalSurname;
        
        @InvocableVariable(label='Apellido Materno' required=true)
        public String maternalSurname;

        @InvocableVariable(label='Nombres (Pila)' required=true)
        public String firstName;

        @InvocableVariable(label='Telefono' required=true)
        public String phone;

        @InvocableVariable(label='Fecha de Nacimiento' required=true)
        public String birthDate;

        @InvocableVariable(label='Email')
        public String email;

        @InvocableVariable(label='Lista de Opciones Dinamicas' description='Pasa aqui la lista requiredFields obtenida en el paso anterior para cruce de codigos.')
        public List<Tech_MueveteSeguroWrappers.RequiredField> allRequiredFields;
    }

    public class PolicyOutput {
        @InvocableVariable(label='ID de Poliza')
        public String policyId;
        @InvocableVariable(label='URL de Pago')
        public String paymentUrl;
        @InvocableVariable(label='Monto Total')
        public Decimal totalAmount;
        @InvocableVariable(label='Error')
        public String errorMessage;
    }

    @InvocableMethod(label='Tech: Emitir Poliza y Pago' description='Emite la poliza realizando un cruce dinamico de opciones para asegurar escalabilidad.')
    public static List<PolicyOutput> execute(List<PolicyInput> inputs) {
        List<PolicyOutput> outputs = new List<PolicyOutput>();
        for (PolicyInput input : inputs) {
            PolicyOutput out = new PolicyOutput();
            try {
                // Extraer opciones de los campos requeridos
                List<Tech_MueveteSeguroWrappers.Option> flatOptions = new List<Tech_MueveteSeguroWrappers.Option>();
                if(input.allRequiredFields != null) {
                    for(Tech_MueveteSeguroWrappers.RequiredField f : input.allRequiredFields) {
                        if(f.options != null) flatOptions.addAll(f.options);
                    }
                }

                Map<String, Object> data = new Map<String, Object>();
                data.put('rfcKey', input.rfc);
                data.put('curp', input.curp);
                data.put('serialNumber', input.vin);
                data.put('phone', input.phone);
                data.put('birthdate', input.birthDate);
                data.put('email', input.email);
                data.put('street', input.street);
                data.put('occupation', input.occupation);
                data.put('maritalStatus', input.maritalStatus);
                data.put('paternalSurname', input.paternalSurname);
                data.put('maternalSurname', input.maternalSurname);
                data.put('fullName', input.firstName);

                // Llamada al servicio con cruce dinámico
                Tech_MueveteSeguroWrappers.PolicyResponse res = 
                    Tech_MueveteSeguroPolicyService.submitInsuredData(input.quotationId, data, flatOptions);
                
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