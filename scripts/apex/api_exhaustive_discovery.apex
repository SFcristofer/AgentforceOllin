System.debug('--- EXHAUSTIVE DISCOVERY ---');
String[] paths = new String[]{
    '/bot/life',
    '/bot/life-quotation',
    '/bot/quotation/life',
    '/bot/catalog/life',
    '/bot/bonds',
    '/bot/fianzas',
    '/bot/fianzas-quotation',
    '/bot/catalog/fianzas',
    '/bot/products/life',
    '/bot/products/fianzas',
    '/bot/v2/quotation',
    '/bot/ramo/vida',
    '/bot/ramo/fianzas'
};

for(String path : paths) {
    try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:MueveteSeguro_Bot_API' + path);
        req.setMethod('GET');
        HttpResponse res = new Http().send(req);
        System.debug('Path: ' + path + ' Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
        
        // Try POST with empty body just in case
        req.setMethod('POST');
        req.setBody('{}');
        res = new Http().send(req);
        System.debug('POST Path: ' + path + ' Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
    } catch (Exception e) {
        System.debug('Path: ' + path + ' Error: ' + e.getMessage());
    }
}
System.debug('--- END EXHAUSTIVE DISCOVERY ---');
