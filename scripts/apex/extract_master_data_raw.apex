System.debug('--- START MASTER DATA EXTRACTION ---');
String baseUrl = 'callout:MueveteSeguro_Bot_API';

String[] paths = new String[]{
    '/bot/insurers',
    '/bot/coverages',
    '/bot/catalog/products',
    '/bot/catalog/ramos'
};

for(String path : paths) {
    try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(baseUrl + path);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        HttpResponse res = new Http().send(req);
        System.debug('DATA_FOR_' + path + ': ' + res.getBody());
    } catch(Exception e) {
        System.debug('ERROR_FOR_' + path + ': ' + e.getMessage());
    }
}
System.debug('--- END MASTER DATA EXTRACTION ---');
