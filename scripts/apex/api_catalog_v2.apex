System.debug('--- CATALOG V2 DISCOVERY ---');
String[] paths = new String[]{
    '/bot/catalog/products',
    '/bot/catalog/life/products',
    '/bot/catalog/bonds/products',
    '/bot/products'
};

for(String path : paths) {
    try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:MueveteSeguro_Bot_API' + path);
        req.setMethod('GET');
        HttpResponse res = new Http().send(req);
        System.debug('Path: ' + path + ' Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
    } catch (Exception e) {
        System.debug('Path: ' + path + ' Error: ' + e.getMessage());
    }
}
