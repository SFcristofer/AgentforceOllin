/**
 * @description Módulo profesional para la gestión de Seguros de Vida.
 * Utiliza la arquitectura base para garantizar seguridad y manejo de errores.
 */
public class Tech_MueveteSeguroLifeService extends Tech_MueveteSeguroBase {

    /**
     * @description Genera una cotización de seguros de vida en la API de Ollin.
     */
    public static Tech_MueveteSeguroWrappers.QuotationResponse getLifeQuotes(Tech_MueveteSeguroWrappers.LifeQuoteRequest lifeReq, String fullName, String phone) {
        
        // MAPEADO INTELIGENTE: Aunque es Vida, el motor universal actual requiere estructura de asegurado.
        Map<String, Object> requestBody = new Map<String, Object>{
            'productType' => 'LIFE',
            'vehicleVersionId' => '00000000-0000-0000-0000-000000000000', // Valor técnico para habilitar el motor
            'coverage' => 'AMPLIA', // Default para inicialización de motor
            'insured' => new Map<String, Object>{
                'name' => fullName,
                'phone' => phone,
                'zipCode' => lifeReq.zipCode,
                'birthDate' => lifeReq.birthDate,
                'gender' => lifeReq.gender
            },
            'metadata' => new Map<String, Object>{
                'isSmoker' => lifeReq.isSmoker,
                'objective' => lifeReq.objective,
                'monthlyContribution' => lifeReq.desiredAmount,
                'term' => lifeReq.term
            }
        };

        HttpResponse res = sendRequest('POST', '/bot/quotation', JSON.serialize(requestBody));
        
        return (Tech_MueveteSeguroWrappers.QuotationResponse) 
            JSON.deserialize(res.getBody(), Tech_MueveteSeguroWrappers.QuotationResponse.class);
    }
}