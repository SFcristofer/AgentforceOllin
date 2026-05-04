System.debug('--- START MASTER DATA EXTRACTION ---');
try {
    System.debug('INSURERS:' + MueveteSeguroService.getInsurers());
    System.debug('COVERAGES_AUTO:' + MueveteSeguroService.getCoverages());
    
    // Attempt to get catalog products or other branches
    String[] extraPaths = new String[]{'/bot/catalog/products', '/bot/catalog/ramos'};
    for(String path : extraPaths) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:MueveteSeguro_Bot_API' + path);
        req.setMethod('GET');
        try {
            HttpResponse res = new Http().send(req);
            System.debug('PATH_' + path.replace('/', '_') + ':' + res.getBody());
        } catch(Exception e) {}
    }
} catch(Exception e) {
    System.debug('ERROR:' + e.getMessage());
}
System.debug('--- END MASTER DATA EXTRACTION ---');
