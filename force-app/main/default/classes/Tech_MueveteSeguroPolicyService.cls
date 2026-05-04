/**
 * @description Módulo de póliza con blindaje total.
 * Cruza datos por Label o por Value para evitar errores de la API.
 */
public class Tech_MueveteSeguroPolicyService extends Tech_MueveteSeguroBase {
    
    public static Tech_MueveteSeguroWrappers.PolicyResponse submitInsuredData(String quotationId, Map<String, Object> dynamicFields, List<Tech_MueveteSeguroWrappers.Option> allOptions) {
        String path = '/bot/quotation/' + quotationId + '/insured';
        
        if (allOptions != null && !allOptions.isEmpty()) {
            for (String fieldKey : dynamicFields.keySet()) {
                String userVal = String.valueOf(dynamicFields.get(fieldKey));
                for (Tech_MueveteSeguroWrappers.Option opt : allOptions) {
                    // BLINDAJE: Si el usuario dio el nombre (Label) O el valor (Value), mapeamos al valor oficial.
                    if ((opt.label != null && userVal.equalsIgnoreCase(opt.label)) || 
                        (opt.value != null && userVal.equalsIgnoreCase(opt.value))) {
                        dynamicFields.put(fieldKey, opt.value);
                        break;
                    }
                }
            }
        }

        String body = JSON.serialize(dynamicFields);
        HttpResponse res = sendRequest('POST', path, body);
        return (Tech_MueveteSeguroWrappers.PolicyResponse) 
            JSON.deserialize(res.getBody(), Tech_MueveteSeguroWrappers.PolicyResponse.class);
    }

    public static Tech_MueveteSeguroWrappers.PolicyResponse getPaymentLink(String policyId) {
        String path = '/bot/policy/' + policyId + '/payment-link';
        HttpResponse res = sendRequest('GET', path, null);
        return (Tech_MueveteSeguroWrappers.PolicyResponse) JSON.deserialize(res.getBody(), Tech_MueveteSeguroWrappers.PolicyResponse.class);
    }

    public static Tech_MueveteSeguroWrappers.PolicyResponse getPolicyStatus(String policyId) {
        String path = '/bot/policy/' + policyId;
        HttpResponse res = sendRequest('GET', path, null);
        return (Tech_MueveteSeguroWrappers.PolicyResponse) JSON.deserialize(res.getBody(), Tech_MueveteSeguroWrappers.PolicyResponse.class);
    }
}