/**
 * @description Acción Invocable para Agentforce: Busca vehículos en el catálogo de Ollin.
 * Paso 1 de 6 en el flujo de seguros de auto.
 */
public class Tech_GetVehicleCatalog {

    public class CatalogRequest {
        @InvocableVariable(label='Tipo de Búsqueda' description='Valores: years, brands, models, versions' required=true)
        public String searchType;
        
        @InvocableVariable(label='Año' description='Año del vehículo (requerido para brands, models, versions)')
        public String year;
        
        @InvocableVariable(label='ID de Marca' description='ID obtenido en búsqueda de brands (requerido para models)')
        public String brandId;
        
        @InvocableVariable(label='ID de Modelo' description='ID obtenido en búsqueda de models (requerido para versions)')
        public String modelId;
    }

    public class CatalogResponse {
        @InvocableVariable(label='Lista de Opciones' description='Items encontrados en el catálogo (ID y Nombre)')
        public List<Tech_MueveteSeguroWrappers.CatalogItem> options;
        
        @InvocableVariable(label='Años Disponibles' description='Solo se llena cuando searchType es years')
        public List<Integer> availableYears;

        @InvocableVariable(label='Error' description='Mensaje de error si la petición falla')
        public String errorMessage;
    }

    @InvocableMethod(label='Tech: Buscar Vehículo en Catálogo' description='Obtiene años, marcas, modelos y versiones del catálogo de Ollin.')
    public static List<CatalogResponse> execute(List<CatalogRequest> requests) {
        List<CatalogResponse> results = new List<CatalogResponse>();
        
        for (CatalogRequest req : requests) {
            CatalogResponse res = new CatalogResponse();
            try {
                if (req.searchType == 'years') {
                    res.availableYears = Tech_MueveteSeguroCatalogService.getYears();
                } else if (req.searchType == 'brands') {
                    res.options = Tech_MueveteSeguroCatalogService.getBrands(req.year);
                } else if (req.searchType == 'models') {
                    res.options = Tech_MueveteSeguroCatalogService.getModels(req.year, req.brandId);
                } else if (req.searchType == 'versions') {
                    res.options = Tech_MueveteSeguroCatalogService.getVersions(req.year, req.modelId);
                }
            } catch (Exception e) {
                res.errorMessage = e.getMessage();
            }
            results.add(res);
        }
        return results;
    }
}