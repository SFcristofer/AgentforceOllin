public class MueveteSeguroConsultas {
    
    public class ConsultaRequest {
        @InvocableVariable(label='Tipo de consulta' description='Que consultar: insurers, coverages, quotation' required=true)
        public String queryType;
        
        @InvocableVariable(label='ID de Cotizacion' description='quotationId si queryType es quotation')
        public String quotationId;
    }
    
    public class ConsultaResponse {
        @InvocableVariable(label='Resultado JSON' description='Respuesta de la consulta')
        public String jsonResult;
        
        @InvocableVariable(label='Exito')
        public Boolean success;
        
        @InvocableVariable(label='Mensaje de error')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Consultar Info MueveteSeguro' description='Consulta aseguradoras disponibles (insurers), tipos de cobertura (coverages), o una cotizacion existente (quotation con quotationId). Usa para obtener info auxiliar del sistema.' category='MueveteSeguro')
    public static List<ConsultaResponse> consultar(List<ConsultaRequest> requests) {
        List<ConsultaResponse> responses = new List<ConsultaResponse>();
        for (ConsultaRequest req : requests) {
            ConsultaResponse resp = new ConsultaResponse();
            try {
                String result;
                if (req.queryType == 'insurers') {
                    result = MueveteSeguroService.getInsurers();
                } else if (req.queryType == 'coverages') {
                    result = MueveteSeguroService.getCoverages();
                } else if (req.queryType == 'quotation') {
                    result = MueveteSeguroService.getQuotation(req.quotationId);
                } else {
                    resp.success = false;
                    resp.errorMessage = 'Tipo no valido. Usa: insurers, coverages o quotation';
                    responses.add(resp);
                    continue;
                }
                resp.jsonResult = result;
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