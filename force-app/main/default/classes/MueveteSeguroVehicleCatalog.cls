public class MueveteSeguroVehicleCatalog {
    
    public class CatalogRequest {
        @InvocableVariable(label='Paso del catalogo' description='Que consultar: years, brands, models, versions' required=true)
        public String step;
        
        @InvocableVariable(label='Ano del vehiculo' description='Ano del vehiculo, ej: 2024')
        public String year;
        
        @InvocableVariable(label='ID de la marca' description='ID de la marca obtenido del paso brands')
        public String brandId;
        
        @InvocableVariable(label='ID del modelo' description='ID del modelo obtenido del paso models')
        public String modelId;
    }
    
    public class CatalogResponse {
        @InvocableVariable(label='Resultado JSON' description='Respuesta del catalogo en formato JSON')
        public String jsonResult;
        
        @InvocableVariable(label='Exito' description='Si la consulta fue exitosa')
        public Boolean success;
        
        @InvocableVariable(label='Mensaje de error' description='Mensaje si hubo error')
        public String errorMessage;
    }
    
    @InvocableMethod(label='Buscar Vehiculo en Catalogo' description='Busca anos, marcas, modelos y versiones de vehiculos disponibles para cotizar seguro de auto. Usa step=years para iniciar, luego brands con year, models con year+brandId, versions con year+modelId.' category='MueveteSeguro')
    public static List<CatalogResponse> searchCatalog(List<CatalogRequest> requests) {
        List<CatalogResponse> responses = new List<CatalogResponse>();
        for (CatalogRequest req : requests) {
            CatalogResponse resp = new CatalogResponse();
            try {
                String result;
                if (req.step == 'years') {
                    result = MueveteSeguroService.getYears();
                } else if (req.step == 'brands') {
                    result = MueveteSeguroService.getBrands(req.year);
                } else if (req.step == 'models') {
                    result = MueveteSeguroService.getModels(req.year, req.brandId);
                } else if (req.step == 'versions') {
                    result = MueveteSeguroService.getVersions(req.year, req.modelId);
                } else {
                    resp.success = false;
                    resp.errorMessage = 'Paso no valido. Usa: years, brands, models o versions';
                    responses.add(resp);
                    continue;
                }
                resp.jsonResult = result;
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