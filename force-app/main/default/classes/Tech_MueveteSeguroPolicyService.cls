/**
 * @description Módulo de póliza con Blindaje de Inteligencia Artificial.
 * Traduce lenguaje natural a códigos técnicos mediante algoritmos de búsqueda flexible.
 */
public class Tech_MueveteSeguroPolicyService extends Tech_MueveteSeguroBase {
    
    /**
     * @description Envía los datos finales del asegurado con mapeo inteligente de etiquetas.
     */
    public static Tech_MueveteSeguroWrappers.PolicyResponse submitInsuredData(String quotationId, Map<String, Object> dynamicFields, List<Tech_MueveteSeguroWrappers.Option> allOptions) {
        String path = '/bot/quotation/' + quotationId + '/insured';
        
        // CEREBRO DE TRADUCCIÓN: Si tenemos opciones, buscamos el mejor match para cada campo dinámico.
        if (allOptions != null && !allOptions.isEmpty()) {
            for (String fieldKey : dynamicFields.keySet()) {
                Object rawVal = dynamicFields.get(fieldKey);
                if (rawVal == null || !(rawVal instanceof String)) continue;
                
                String userVal = ((String)rawVal).trim().toUpperCase();
                
                for (Tech_MueveteSeguroWrappers.Option opt : allOptions) {
                    String optLabel = (opt.label != null) ? opt.label.toUpperCase() : '';
                    String optValue = (opt.value != null) ? opt.value.toUpperCase() : '';
                    
                    // ALGORITMO DE MAPEO INTELIGENTE (Multi-nivel)
                    // 1. Match exacto con el código (ej. "C3" == "C3")
                    // 2. Match exacto con la etiqueta (ej. "CASADO" == "CASADO")
                    // 3. Contención (ej. "INE" está dentro de "CREDENCIAL IFE / INE")
                    if (userVal == optValue || userVal == optLabel || 
                        (optLabel != '' && optLabel.contains(userVal)) || 
                        (optLabel != '' && userVal.contains(optLabel))) {
                        
                        dynamicFields.put(fieldKey, opt.value); // Intercambiamos texto por código técnico
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