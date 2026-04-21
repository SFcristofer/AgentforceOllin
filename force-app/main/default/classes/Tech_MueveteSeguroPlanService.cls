/**
 * @description Módulo especializado para la selección de plan y campos dinámicos.
 * El Agente de Agentforce depende de esto para pedir datos específicos por aseguradora.
 */
public class Tech_MueveteSeguroPlanService extends Tech_MueveteSeguroBase {
    
    /**
     * @description Selecciona una aseguradora y obtiene los campos adicionales requeridos.
     * @param quotationId ID de la cotización previa.
     * @param insurer Nombre de la aseguradora elegida.
     * @return Lista de RequiredField para que el Agente los pregunte al usuario.
     */
    public static List<Tech_MueveteSeguroWrappers.RequiredField> selectPlan(String quotationId, String insurer) {
        String path = '/bot/quotation/' + quotationId + '/select';
        Map<String, String> bodyMap = new Map<String, String>{ 'insurer' => insurer };
        
        HttpResponse res = sendRequest('POST', path, JSON.serialize(bodyMap));
        
        Tech_MueveteSeguroWrappers.SelectPlanResponse data = (Tech_MueveteSeguroWrappers.SelectPlanResponse)
            JSON.deserialize(res.getBody(), Tech_MueveteSeguroWrappers.SelectPlanResponse.class);
            
        return data.requiredFields;
    }

    /**
     * @description Obtiene las opciones de financiamiento (Step 3 Auxiliar).
     */
    public static List<Tech_MueveteSeguroWrappers.Option> getInstallmentOptions(String quotationId) {
        String path = '/bot/installment-options?quotationId=' + quotationId;
        HttpResponse res = sendRequest('GET', path, null);
        
        // La API devuelve una lista de opciones con monto por parcela
        Tech_MueveteSeguroWrappers.CatalogListResponse data = (Tech_MueveteSeguroWrappers.CatalogListResponse) 
            JSON.deserialize(res.getBody().replace('"items":', '"optionItems":'), Tech_MueveteSeguroWrappers.CatalogListResponse.class);
            
        // Convertir para que sea compatible con el Agente (Label/Value)
        // ... Lógica adicional si se requiere ...
        return null; // A implementar según sea necesario
    }
}