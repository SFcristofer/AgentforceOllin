public with sharing class Tech_ProductCatalogProvider {
    
    public class ProductDiscoveryRequest {
        @InvocableVariable(required=true description='Ramo técnico para filtrar productos (ej: Auto, Vida, GMM, PPR, Fianzas)')
        public String ramo;
    }
    
    public class ProductDiscoveryResult {
        @InvocableVariable(description='Lista de nombres de productos disponibles para mostrar al cliente')
        public List<String> productNames;
        
        @InvocableVariable(description='Lista de IDs de productos de Salesforce')
        public List<Id> productIds;

        @InvocableVariable(description='Resumen formateado de opciones para el agente')
        public String formattedOptions;
    }

    @InvocableMethod(label='Tech: Obtener Catálogo por Ramo' description='Devuelve los productos activos de Salesforce filtrados por el ramo solicitado para Agentforce.')
    public static List<ProductDiscoveryResult> getProductsByRamo(List<ProductDiscoveryRequest> requests) {
        List<ProductDiscoveryResult> results = new List<ProductDiscoveryResult>();
        
        for (ProductDiscoveryRequest req : requests) {
            ProductDiscoveryResult res = new ProductDiscoveryResult();
            res.productNames = new List<String>();
            res.productIds = new List<Id>();
            
            String searchCodePrefix = '';
            String cleanRamo = (req.ramo != null) ? req.ramo.toUpperCase() : '';
            
            // Mapeo de Ramo a prefijo de ProductCode (estandarizado con la API)
            if (cleanRamo.contains('AUTO') || cleanRamo.contains('VEHICULO')) {
                searchCodePrefix = 'AUTO-%';
            } else if (cleanRamo.contains('VIDA')) {
                searchCodePrefix = 'VIDA-%';
            } else if (cleanRamo.contains('GMM') || cleanRamo.contains('MEDIC') || cleanRamo.contains('GASTOS')) {
                searchCodePrefix = 'GMM-%';
            } else if (cleanRamo.contains('PPR') || cleanRamo.contains('RETIRO') || cleanRamo.contains('AHORRO')) {
                searchCodePrefix = 'PPR-%';
            } else if (cleanRamo.contains('FIANZA')) {
                searchCodePrefix = 'FZA-%';
            }
            
            List<Product2> products;
            if (String.isNotBlank(searchCodePrefix)) {
                products = [SELECT Id, Name FROM Product2 WHERE ProductCode LIKE :searchCodePrefix AND IsActive = true ORDER BY Name ASC];
            } else {
                // Fallback: Si no se identifica el ramo, traer productos populares o dejar vacío para seguridad
                products = new List<Product2>();
            }
            
            if (!products.isEmpty()) {
                String options = 'Opciones de planes para ' + req.ramo + ':\n';
                for (Product2 p : products) {
                    res.productNames.add(p.Name);
                    res.productIds.add(p.Id);
                    options += '- ' + p.Name + '\n';
                }
                res.formattedOptions = options;
            } else {
                res.formattedOptions = 'No se encontraron productos disponibles para el ramo: ' + req.ramo;
            }
            
            results.add(res);
        }
        
        return results;
    }
}
