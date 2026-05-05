/**
 * @description Acción Invocable de Alta Precisión para Agentforce.
 * Contiene metadatos descriptivos detallados para que la IA entienda cuándo y qué pedir.
 */
public class Tech_SubmitInsuredData {

    public class PolicyInput {
        @InvocableVariable(label='ID de Cotizacion' description='El identificador único de la cotización seleccionada en el paso anterior.' required=true)
        public String quotationId;
        
        @InvocableVariable(label='RFC' description='Registro Federal de Contribuyentes (13 caracteres). Pídelo si la aseguradora lo requiere para la emisión.')
        public String rfc;
        
        @InvocableVariable(label='CURP' description='Clave Única de Registro de Población (18 caracteres). Pídelo solo si Tech_ProcessRequiredFields indica que es obligatorio.')
        public String curp;
        
        @InvocableVariable(label='Numero de Serie (VIN)' description='Número de identificación vehicular de 17 caracteres. Es indispensable para la emisión de la póliza.')
        public String vin;
        
        @InvocableVariable(label='Calle y Numero' description='Dirección completa del asegurado incluyendo calle, número exterior e interior.')
        public String street;
        
        @InvocableVariable(label='Ocupacion' description='Actividad laboral del cliente. Usa los valores proporcionados por el catálogo de la aseguradora.')
        public String occupation;

        @InvocableVariable(label='Estado Civil' description='Situación civil del cliente (C, D, S, U, V).')
        public String maritalStatus;
        
        @InvocableVariable(label='Apellido Paterno' description='Primer apellido del asegurado. Es un dato obligatorio para el contrato.' required=true)
        public String paternalSurname;
        
        @InvocableVariable(label='Apellido Materno' description='Segundo apellido del asegurado. Si no lo tienes, pídelo al usuario.' required=true)
        public String maternalSurname;

        @InvocableVariable(label='Nombres (Pila)' description='Nombre o nombres del asegurado (sin apellidos).' required=true)
        public String firstName;

        @InvocableVariable(label='Telefono' description='Número telefónico de contacto a 10 dígitos.' required=true)
        public String phone;

        @InvocableVariable(label='Fecha de Nacimiento' description='Fecha en formato AAAA-MM-DD del asegurado.' required=true)
        public String birthDate;

        @InvocableVariable(label='Email' description='Correo electrónico para el envío de la póliza digital.')
        public String email;

        @InvocableVariable(label='Lista de Opciones Dinamicas' description='Recibe la lista requiredFields de la acción anterior para validar códigos internos de la aseguradora.')
        public List<Tech_MueveteSeguroWrappers.RequiredField> allRequiredFields;
    }

    public class PolicyOutput {
        @InvocableVariable(label='ID de Poliza' description='Identificador interno de la póliza generada.')
        public String policyId;
        @InvocableVariable(label='URL de Pago' description='Enlace directo a la pasarela de pago para el cliente.')
        public String paymentUrl;
        @InvocableVariable(label='Monto Total' description='Costo final de la póliza en pesos mexicanos.')
        public Decimal totalAmount;
        @InvocableVariable(label='Error' description='Mensaje detallado en caso de que la emisión falle.')
        public String errorMessage;
    }

    @InvocableMethod(label='Tech: Emitir Poliza y Pago' description='Acción final para generar la póliza y el link de pago. Utiliza todos los datos recolectados del cliente.')
    public static List<PolicyOutput> execute(List<PolicyInput> inputs) {
        List<PolicyOutput> outputs = new List<PolicyOutput>();
        for (PolicyInput input : inputs) {
            PolicyOutput out = new PolicyOutput();
            try {
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
                data.put('fullName', input.firstName); // HDI requiere esto como nombre de pila
                
                // Mapeo extendido para asegurar éxito
                data.put('firstName', input.firstName);
                data.put('lastName', input.paternalSurname + ' ' + input.maternalSurname);

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