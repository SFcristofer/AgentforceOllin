/**
 * @description Clase base para manejar la comunicación HTTP con la API de Ollin.
 * Centraliza headers, timeouts y manejo de errores para escalabilidad.
 */
public virtual class Tech_MueveteSeguroBase {
    
    public static final String NAMED_CREDENTIAL = 'callout:MueveteSeguro_Bot_API';
    
    public class ServiceException extends Exception {}

    /**
     * @description Ejecuta una petición HTTP genérica con manejo de errores básico.
     */
    public static HttpResponse sendRequest(String method, String path, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + path);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        
        if (String.isNotBlank(body)) {
            req.setBody(body);
        }
        
        req.setTimeout(30000); 
        
        HttpResponse res = new Http().send(req);
        
        if (res.getStatusCode() == 429) {
            throw new ServiceException('Límite de peticiones excedido. Por favor intenta en un minuto.');
        }
        
        if (res.getStatusCode() >= 500) {
            throw new ServiceException('Error en el servidor de Ollin. Código: ' + res.getStatusCode());
        }
        
        return res;
    }
}