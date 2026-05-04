/**
 * @description Acción Invocable para Agentforce: Busca vehículos en el catálogo de Ollin.
 * Paso 1 de 6 en el flujo de seguros de auto.
 */
public class Tech_GetVehicleCatalog {

    public class CatalogRequest {
        @InvocableVariable(label='Tipo de Busqueda' description='Define que nivel de catalogo buscar. Los valores permitidos son: years (para años), brands (para marcas), models (para modelos) o versions (para versiones del auto).' required=true)
        public String searchType;
        
        @InvocableVariable(label='Anio' description='El año de fabricacion del vehiculo. Es obligatorio cuando searchType es brands, models o versions.')
        public String year;
        
        @InvocableVariable(label='ID de Marca' description='El identificador unico de la marca obtenido previamente. Es obligatorio cuando searchType es models.')
        public String brandId;
        
        @InvocableVariable(label='ID de Modelo' description='El identificador unico del modelo obtenido previamente. Es obligatorio cuando searchType es versions.')
        public String modelId;
    }

    public class CatalogResponse {
        @InvocableVariable(label='Lista de Opciones' description='Contiene una lista de objetos con el ID y el Nombre de las opciones encontradas (Marcas, Modelos o Versiones).')
        public List<Tech_MueveteSeguroWrappers.CatalogItem> options;
        
        @InvocableVariable(label='Anios Disponibles' description='Lista numerica de los años disponibles en el catalogo de Ollin.')
        public List<Integer> availableYears;

        @InvocableVariable(label='Error' description='Mensaje detallado si ocurre un problema tecnico con la API de catalogos.')
        public String errorMessage;
    }

    @InvocableMethod(label='Tech: Buscar Vehiculo en Catalogo' description='Accion obligatoria para el Paso 1. Consulta el catalogo oficial de Ollin para identificar el año, marca, modelo y version tecnica del vehiculo del usuario.')
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