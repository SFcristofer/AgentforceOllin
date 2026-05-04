System.debug('--- LIFE QUOTATION TEST ---');
Map<String, Object> payload = new Map<String, Object>();
payload.put('productType', 'LIFE'); // Speculative field
payload.put('coverage', 'AMPLIA');
Map<String, Object> ins = new Map<String, Object>();
ins.put('name', 'Test Life');
ins.put('phone', '+527711154775');
ins.put('zipCode', '43203');
ins.put('birthDate', '1990-01-01');
ins.put('gender', 'M');
payload.put('insured', ins);

try {
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:MueveteSeguro_Bot_API/bot/quotation');
    req.setMethod('POST');
    req.setHeader('Content-Type', 'application/json');
    req.setBody(JSON.serialize(payload));
    HttpResponse res = new Http().send(req);
    System.debug('Status: ' + res.getStatusCode() + ' Body: ' + res.getBody());
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
}
