System.debug('--- INSURERS RAMO DISCOVERY ---');
String[] ramos = new String[]{'AUTO', 'VIDA', 'GMM', 'FIANZAS'};

for(String ramo : ramos) {
    try {
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:MueveteSeguro_Bot_API/bot/insurers?ramo=' + ramo);
        req.setMethod('GET');
        HttpResponse res = new Http().send(req);
        System.debug('Ramo: ' + ramo + ' Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
    } catch (Exception e) {
        System.debug('Ramo: ' + ramo + ' Error: ' + e.getMessage());
    }
}
