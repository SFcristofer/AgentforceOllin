public class MueveteSeguroPolicyStatus {
    
    public class PolicyRequest {
        @InvocableVariable(label='ID de Poliza' description='policyId de la poliza a consultar' required=true)
        public String policyId;
        
        @InvocableVariable(label='Obtener enlace de pago' description='true para obtener/regenerar el enlace de pago')
        public Boolean getPaymentLink;
    }
    
    public class PolicyResponse {
        @InvocableVariable(label='Resultado JSON' description='Estado de la poliza o enlace de pago')
        public String jsonResult;
        
        @InvocableVariable(label='Estado' description='pending, approved o refused')
        public String status;
        
        @InvocableVariable(label='URL de Pago' description='Enlace de pago si se solicito')
        public String paymentUrl;
        
        @InvocableVariable(label='Exito')
        public Boolean success;
        
        @InvocableVariable(label='Mensaje de error')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Consultar Estado de Poliza' description='Consulta el estado de una poliza (pending/approved/refused) y opcionalmente obtiene el enlace de pago. Estados: pending=esperando pago, approved=poliza emitida, refused=rechazada.' category='MueveteSeguro')
    public static List<PolicyResponse> checkPolicy(List<PolicyRequest> requests) {
        List<PolicyResponse> responses = new List<PolicyResponse>();
        for (PolicyRequest req : requests) {
            PolicyResponse resp = new PolicyResponse();
            try {
                if (req.getPaymentLink == true) {
                    String linkResult = MueveteSeguroService.getPaymentLink(req.policyId);
                    resp.jsonResult = linkResult;
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(linkResult);
                    if (parsed.containsKey('paymentUrl')) {
                        resp.paymentUrl = String.valueOf(parsed.get('paymentUrl'));
                    }
                } else {
                    String statusResult = MueveteSeguroService.getPolicyStatus(req.policyId);
                    resp.jsonResult = statusResult;
                    Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(statusResult);
                    if (parsed.containsKey('status')) {
                        resp.status = String.valueOf(parsed.get('status'));
                    }
                }
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