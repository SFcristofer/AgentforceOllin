public class MueveteSeguroQuotation {
    
    public class QuotationRequest {
        @InvocableVariable(label='ID Version Vehiculo' description='vehicleVersionId del catalogo' required=true)
        public String vehicleVersionId;
        
        @InvocableVariable(label='Nombre del asegurado' description='Nombre completo del conductor' required=true)
        public String insuredName;
        
        @InvocableVariable(label='Telefono' description='Telefono con codigo de pais ej +525512345678' required=true)
        public String phone;
        
        @InvocableVariable(label='Email' description='Correo electronico del asegurado')
        public String email;
        
        @InvocableVariable(label='Codigo Postal' description='CP mexicano de 5 digitos' required=true)
        public String zipCode;
        
        @InvocableVariable(label='Fecha de nacimiento' description='Formato ISO 8601: 1990-03-15' required=true)
        public String birthDate;
        
        @InvocableVariable(label='Genero' description='M para masculino, F para femenino' required=true)
        public String gender;
        
        @InvocableVariable(label='Tipo de cobertura' description='AMPLIA, LIMITADA o RC' required=true)
        public String coverage;
    }
    
    public class QuotationResponse {
        @InvocableVariable(label='Resultado JSON' description='Cotizacion completa con precios de aseguradoras')
        public String jsonResult;
        
        @InvocableVariable(label='ID de Cotizacion' description='quotationId para los siguientes pasos')
        public String quotationId;
        
        @InvocableVariable(label='Exito')
        public Boolean success;
        
        @InvocableVariable(label='Mensaje de error')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Generar Cotizacion de Seguro' description='Genera una cotizacion de seguro de auto consultando las 5 aseguradoras (HDI, ANA, GNP, QUALITAS, CHUBB). Devuelve precios, coberturas y opciones de pago. Requiere datos del vehiculo y del asegurado.' category='MueveteSeguro')
    public static List<QuotationResponse> createQuotation(List<QuotationRequest> requests) {
        List<QuotationResponse> responses = new List<QuotationResponse>();
        for (QuotationRequest req : requests) {
            QuotationResponse resp = new QuotationResponse();
            try {
                String result = MueveteSeguroService.createQuotation(
                    req.vehicleVersionId, req.insuredName, req.phone, req.email,
                    req.zipCode, req.birthDate, req.gender, req.coverage
                );
                resp.jsonResult = result;
                resp.success = true;
                // Extract quotationId from response
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
                if (parsed.containsKey('quotationId')) {
                    resp.quotationId = String.valueOf(parsed.get('quotationId'));
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