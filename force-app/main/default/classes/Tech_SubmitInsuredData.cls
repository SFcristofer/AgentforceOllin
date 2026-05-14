/**
 * @description Acción Invocable de Alta Precisión para Agentforce.
 * Procesa dinámicamente cualquier campo requerido por la aseguradora.
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

        @InvocableVariable(label='Lista de Opciones Dinamicas' description='Pasa aqui la lista requerida obtenida en el paso 3.')
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

    @InvocableMethod(label='Tech: Emitir Poliza y Pago' description='Genera la póliza enviando los datos recolectados y traduciendo etiquetas automáticamente.')
    public static List<PolicyOutput> execute(List<PolicyInput> inputs) {
        List<PolicyOutput> outputs = new List<PolicyOutput>();
        for (PolicyInput input : inputs) {
            PolicyOutput out = new PolicyOutput();
            try {
                Map<String, Object> data = new Map<String, Object>();
                List<Tech_MueveteSeguroWrappers.Option> flatOptions = new List<Tech_MueveteSeguroWrappers.Option>();

                // 1. RECOLECCIÓN DE DATOS DINÁMICOS (Ej. Placas, INE)
                if(input.allRequiredFields != null) {
                    for(Tech_MueveteSeguroWrappers.RequiredField f : input.allRequiredFields) {
                        if(String.isNotBlank(f.value)) {
                            data.put(f.field, f.value); // Guardamos la respuesta del usuario para ese campo
                        }
                        if(f.options != null) flatOptions.addAll(f.options);
                    }
                }

                // 2. DATOS BASE (Con prioridad sobre los dinámicos)
                if(String.isNotBlank(input.rfc)) data.put('rfcKey', input.rfc);
                if(String.isNotBlank(input.curp)) data.put('curp', input.curp);
                if(String.isNotBlank(input.vin)) data.put('serialNumber', input.vin); 
                data.put('phone', input.phone);
                data.put('birthdate', input.birthDate);
                data.put('email', input.email);
                data.put('street', input.street);
                if(String.isNotBlank(input.occupation)) data.put('occupation', input.occupation);
                if(String.isNotBlank(input.maritalStatus)) data.put('maritalStatus', input.maritalStatus);
                data.put('paternalSurname', input.paternalSurname);
                data.put('maternalSurname', input.maternalSurname);
                data.put('fullName', input.firstName); 
                data.put('firstName', input.firstName);
                data.put('lastName', input.paternalSurname + ' ' + input.maternalSurname);

                // 3. LLAMADA AL SERVICIO (Con Cerebro de Traducción para etiquetas)
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