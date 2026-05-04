System.debug('--- DOCS DISCOVERY ---');
String[] paths = new String[]{
    '/api-docs',
    '/swagger-ui.html',
    '/docs',
    '/swagger.json',
    '/openapi.json',
    '/bot/docs'
};

for(String path : paths) {
    try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:MueveteSeguro_Bot_API' + path);
        req.setMethod('GET');
        HttpResponse res = new Http().send(req);
        System.debug('Path: ' + path + ' Status: ' + res.getStatusCode());
        if(res.getStatusCode() == 200) {
            System.debug('Body preview: ' + res.getBody().substring(0, Math.min(200, res.getBody().length())));
        }
    } catch (Exception e) {
        System.debug('Path: ' + path + ' Error: ' + e.getMessage());
    }
}
