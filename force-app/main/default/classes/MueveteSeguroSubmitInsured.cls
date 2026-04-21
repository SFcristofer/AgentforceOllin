public class MueveteSeguroSubmitInsured {
    
    public class InsuredRequest {
        @InvocableVariable(label='ID de Cotizacion' description='quotationId de la cotizacion en curso' required=true)
        public String quotationId;
        
        @InvocableVariable(label='Datos del asegurado JSON' description='JSON con los campos requeridos: fullName, paternalSurname, maternalSurname, rfcKey, phone, email, street, birthdate, serialNumber, occupation, maritalStatus, gender, personType, etc.' required=true)
        public String insuredDataJson;
    }
    
    public class InsuredResponse {
        @InvocableVariable(label='Resultado JSON' description='Respuesta con policyId, paymentUrl y status')
        public String jsonResult;
        
        @InvocableVariable(label='ID de Poliza' description='policyId de la poliza creada')
        public String policyId;
        
        @InvocableVariable(label='URL de Pago' description='Enlace de pago para enviar al cliente')
        public String paymentUrl;
        
        @InvocableVariable(label='Exito')
        public Boolean success;
        
        @InvocableVariable(label='Mensaje de error')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Enviar Datos y Generar Poliza' description='Envia los datos completos del asegurado para generar la poliza y obtener el enlace de pago. fullName es solo nombre de pila sin apellidos. Estado civil: C=Casado, D=Divorciado, S=Soltero, U=Union Libre, V=Viudo.' category='MueveteSeguro')
    public static List<InsuredResponse> submitInsured(List<InsuredRequest> requests) {
        List<InsuredResponse> responses = new List<InsuredResponse>();
        for (InsuredRequest req : requests) {
            InsuredResponse resp = new InsuredResponse();
            try {
                String result = MueveteSeguroService.submitInsuredData(req.quotationId, req.insuredDataJson);
                resp.jsonResult = result;
                resp.success = true;
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
                if (parsed.containsKey('policyId')) {
                    resp.policyId = String.valueOf(parsed.get('policyId'));
                }
                if (parsed.containsKey('paymentUrl')) {
                    resp.paymentUrl = String.valueOf(parsed.get('paymentUrl'));
                }
            } catch (Exception e) {
                resp.success = false;
                resp.errorMessage = e.getMessage();
            }
            responses.add(resp);
        }
        return responses;
    }
}