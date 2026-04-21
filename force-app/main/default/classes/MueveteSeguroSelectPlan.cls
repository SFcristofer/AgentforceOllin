public class MueveteSeguroSelectPlan {
    
    public class SelectRequest {
        @InvocableVariable(label='ID de Cotizacion' description='quotationId obtenido al generar la cotizacion' required=true)
        public String quotationId;
        
        @InvocableVariable(label='Aseguradora' description='HDI, ANA, GNP, QUALITAS o CHUBB' required=true)
        public String insurer;
    }
    
    public class SelectResponse {
        @InvocableVariable(label='Resultado JSON' description='Campos requeridos para emitir la poliza')
        public String jsonResult;
        
        @InvocableVariable(label='Exito')
        public Boolean success;
        
        @InvocableVariable(label='Mensaje de error')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Seleccionar Plan de Seguro' description='Selecciona la aseguradora elegida por el cliente. Devuelve los campos adicionales requeridos (requiredFields) para emitir la poliza. Cada aseguradora pide datos diferentes.' category='MueveteSeguro')
    public static List<SelectResponse> selectPlan(List<SelectRequest> requests) {
        List<SelectResponse> responses = new List<SelectResponse>();
        for (SelectRequest req : requests) {
            SelectResponse resp = new SelectResponse();
            try {
                resp.jsonResult = MueveteSeguroService.selectPlan(req.quotationId, req.insurer);
                resp.success = true;
            } catch (Exception e) {
                resp.success = false;
                resp.errorMessage = e.getMessage();
            }
            responses.add(resp);
        }
        return responses;
    }
}