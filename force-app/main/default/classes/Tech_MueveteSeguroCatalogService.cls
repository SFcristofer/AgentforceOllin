/**
 * @description Módulo especializado para el catálogo de vehículos.
 */
public class Tech_MueveteSeguroCatalogService extends Tech_MueveteSeguroBase {
    
    public static List<Integer> getYears() {
        HttpResponse res = sendRequest('GET', '/bot/catalog/years', null);
        Tech_MueveteSeguroWrappers.CatalogListResponse data = (Tech_MueveteSeguroWrappers.CatalogListResponse) 
            JSON.deserialize(res.getBody().replace('"items":', '"yearItems":'), Tech_MueveteSeguroWrappers.CatalogListResponse.class);
        return data.yearItems;
    }

    public static List<Tech_MueveteSeguroWrappers.CatalogItem> getBrands(String year) {
        String path = '/bot/catalog/brands?year=' + EncodingUtil.urlEncode(year, 'UTF-8');
        HttpResponse res = sendRequest('GET', path, null);
        Tech_MueveteSeguroWrappers.CatalogListResponse data = (Tech_MueveteSeguroWrappers.CatalogListResponse) 
            JSON.deserialize(res.getBody(), Tech_MueveteSeguroWrappers.CatalogListResponse.class);
        return data.items;
    }

    public static List<Tech_MueveteSeguroWrappers.CatalogItem> getModels(String year, String brandId) {
        String path = '/bot/catalog/models?year=' + year + '&brandId=' + brandId;
        HttpResponse res = sendRequest('GET', path, null);
        Tech_MueveteSeguroWrappers.CatalogListResponse data = (Tech_MueveteSeguroWrappers.CatalogListResponse) 
            JSON.deserialize(res.getBody(), Tech_MueveteSeguroWrappers.CatalogListResponse.class);
        return data.items;
    }

    public static List<Tech_MueveteSeguroWrappers.CatalogItem> getVersions(String year, String modelId) {
        String path = '/bot/catalog/versions?year=' + year + '&modelId=' + modelId;
        HttpResponse res = sendRequest('GET', path, null);
        
        // CORRECCIÓN CRÍTICA: La API de versiones usa "description" en lugar de "name".
        // Mapeamos dinámicamente para que el Agente reciba nombres legibles.
        String jsonBody = res.getBody().replace('"description":', '"name":');
        
        Tech_MueveteSeguroWrappers.CatalogListResponse data = (Tech_MueveteSeguroWrappers.CatalogListResponse) 
            JSON.deserialize(jsonBody, Tech_MueveteSeguroWrappers.CatalogListResponse.class);
        return data.items;
    }
}