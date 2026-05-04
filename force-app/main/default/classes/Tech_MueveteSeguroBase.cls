/**
 * @description Clase base profesional con manejo robusto de errores de API.
 */
public virtual class Tech_MueveteSeguroBase {
    
    public static final String NAMED_CREDENTIAL = 'callout:MueveteSeguro_Bot_API';
    
    public class ServiceException extends Exception {}

    public static HttpResponse sendRequest(String method, String path, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + path);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        
        if (String.isNotBlank(body)) req.setBody(body);
        req.setTimeout(30000); 
        
        HttpResponse res = new Http().send(req);
        
        // MANEJO ROBUSTO DE ERRORES:
        if (res.getStatusCode() >= 400) {
            String errorMsg = 'Error de la API (Status ' + res.getStatusCode() + ')';
            try {
                // Intentamos extraer el mensaje de error real de la API si viene en el JSON
                Map<String, Object> errorJson = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
                if (errorJson.containsKey('message')) errorMsg = (String) errorJson.get('message');
                else if (errorJson.containsKey('error')) errorMsg = (String) errorJson.get('error');
            } catch (Exception e) {
                errorMsg += ': ' + res.getBody();
            }
            throw new ServiceException(errorMsg);
        }
        
        return res;
    }
}