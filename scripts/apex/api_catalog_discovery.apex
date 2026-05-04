System.debug('--- CATALOG DISCOVERY ---');
String[] paths = new String[]{
    '/bot/catalog/ramos',
    '/bot/catalog/branches',
    '/bot/catalog/types',
    '/bot/catalog/products'
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
