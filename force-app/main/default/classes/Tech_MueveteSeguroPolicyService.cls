/**
 * @description Módulo especializado para la emisión de pólizas y gestión de pagos.
 * Maneja los datos dinámicos requeridos por cada aseguradora.
 */
public class Tech_MueveteSeguroPolicyService extends Tech_MueveteSeguroBase {
    
    /**
     * @description Envía los datos finales del asegurado para emitir la póliza.
     * @param quotationId ID de la cotización seleccionada.
     * @param dynamicFields Mapa con los campos dinámicos recolectados (RFC, VIN, etc.).
     * @return Tech_MueveteSeguroWrappers.PolicyResponse con el ID de póliza y link de pago inicial.
     */
    public static Tech_MueveteSeguroWrappers.PolicyResponse submitInsuredData(String quotationId, Map<String, Object> dynamicFields) {
        String path = '/bot/quotation/' + quotationId + '/insured';
        
        // Aplicar Reglas de Oro de Formateo antes de enviar
        formatPolicyData(dynamicFields);
        
        String body = JSON.serialize(dynamicFields);
        HttpResponse res = sendRequest('POST', path, body);
        
        return (Tech_MueveteSeguroWrappers.PolicyResponse) 
            JSON.deserialize(res.getBody(), Tech_MueveteSeguroWrappers.PolicyResponse.class);
    }

    /**
     * @description Obtiene o refresca el enlace de pago de una póliza existente.
     */
    public static Tech_MueveteSeguroWrappers.PolicyResponse getPaymentLink(String policyId) {
        String path = '/bot/policy/' + policyId + '/payment-link';
        HttpResponse res = sendRequest('GET', path, null);
        
        return (Tech_MueveteSeguroWrappers.PolicyResponse) 
            JSON.deserialize(res.getBody(), Tech_MueveteSeguroWrappers.PolicyResponse.class);
    }

    /**
     * @description Consulta el estado actual de la póliza (Paso 6).
     */
    public static Tech_MueveteSeguroWrappers.PolicyResponse getPolicyStatus(String policyId) {
        String path = '/bot/policy/' + policyId;
        HttpResponse res = sendRequest('GET', path, null);
        
        return (Tech_MueveteSeguroWrappers.PolicyResponse) 
            JSON.deserialize(res.getBody(), Tech_MueveteSeguroWrappers.PolicyResponse.class);
    }

    /**
     * @description Aplica las Reglas de Oro de Ollin:
     * - Nombres separados de apellidos.
     * - Email obligatorio para ciertas aseguradoras (se asume validado por el Agente).
     * - Formateo de MaritalStatus y Gender.
     */
    private static void formatPolicyData(Map<String, Object> data) {
        if (data.containsKey('maritalStatus')) {
            String ms = String.valueOf(data.get('maritalStatus')).toUpperCase().substring(0,1);
            data.put('maritalStatus', ms);
        }
        // Agregaremos más formateos según la lista de requiredFields devuelta en el Paso 3.
    }
}