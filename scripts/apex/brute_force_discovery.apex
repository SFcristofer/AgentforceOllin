String[] paths = new String[]{
    '/bot/institutions',
    '/bot/catalog/institutions',
    '/bot/catalog/insurers',
    '/bot/products',
    '/bot/catalog/products',
    '/bot/catalog/categories',
    '/bot/catalog/insurance-types',
    '/bot/catalog/ramos',
    '/bot/metadata'
};

for(String path : paths) {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:MueveteSeguro_Bot_API' + path);
    req.setMethod('GET');
    try {
        HttpResponse res = new Http().send(req);
        if(res.getStatusCode() == 200) {
            System.debug('FOUND_PATH: ' + path + ' Body: ' + res.getBody());
        } else {
            System.debug('NOT_FOUND_PATH: ' + path + ' Status: ' + res.getStatusCode());
        }
    } catch(Exception e) {
        System.debug('ERROR_PATH: ' + path + ' Message: ' + e.getMessage());
    }
}
