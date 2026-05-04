System.debug('--- API DISCOVERY ---');
String[] paths = new String[]{
    '/bot/catalog',
    '/bot/products',
    '/bot/ramos',
    '/bot/insurance-types',
    '/bot/categories'
};

for(String path : paths) {
    try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:MueveteSeguro_Bot_API' + path);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        HttpResponse res = new Http().send(req);
        System.debug('Path: ' + path + ' Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
    } catch (Exception e) {
        System.debug('Path: ' + path + ' Error: ' + e.getMessage());
    }
}
System.debug('--- END DISCOVERY ---');
