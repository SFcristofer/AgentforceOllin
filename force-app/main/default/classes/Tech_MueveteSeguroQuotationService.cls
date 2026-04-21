/**
 * @description Módulo especializado para la generación de cotizaciones.
 * Implementa validaciones de formato para asegurar la compatibilidad con la API.
 */
public class Tech_MueveteSeguroQuotationService extends Tech_MueveteSeguroBase {
    
    /**
     * @description Genera una cotización síncrona.
     * @param request Objeto con los datos del vehículo y el asegurado.
     * @return Tech_MueveteSeguroWrappers.QuotationResponse con los resultados por aseguradora.
     */
    public static Tech_MueveteSeguroWrappers.QuotationResponse createQuotation(Tech_MueveteSeguroWrappers.QuotationRequest request) {
        // Validaciones de Reglas de Oro
        validateRequest(request);
        
        String body = JSON.serialize(request, true); // true para omitir nulos
        HttpResponse res = sendRequest('POST', '/bot/quotation', body);
        
        return (Tech_MueveteSeguroWrappers.QuotationResponse) 
            JSON.deserialize(res.getBody(), Tech_MueveteSeguroWrappers.QuotationResponse.class);
    }

    /**
     * @description Valida formatos obligatorios antes de enviar a la API.
     */
    private static void validateRequest(Tech_MueveteSeguroWrappers.QuotationRequest req) {
        if (req.insured == null) throw new ServiceException('Datos del asegurado son obligatorios.');
        
        // 1. Validar Teléfono (+52 obligatorio si no viene)
        if (String.isNotBlank(req.insured.phone) && !req.insured.phone.startsWith('+')) {
            req.insured.phone = '+52' + req.insured.phone.replaceAll('[^0-9]', '');
        }

        // 2. Validar CP (5 dígitos)
        if (String.isNotBlank(req.insured.zipCode)) {
            req.insured.zipCode = req.insured.zipCode.replaceAll('[^0-9]', '');
            if (req.insured.zipCode.length() != 5) throw new ServiceException('El Código Postal debe ser de 5 dígitos.');
        }

        // 3. Validar Género (M o F)
        if (String.isNotBlank(req.insured.gender)) {
            req.insured.gender = req.insured.gender.toUpperCase().substring(0,1);
            if (req.insured.gender != 'M' && req.insured.gender != 'F') {
                throw new ServiceException('El género debe ser M o F.');
            }
        }
    }
}