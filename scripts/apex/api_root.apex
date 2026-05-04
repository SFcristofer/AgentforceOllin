HttpRequest req = new HttpRequest();
req.setEndpoint('callout:MueveteSeguro_Bot_API/bot');
req.setMethod('GET');
HttpResponse res = new Http().send(req);
System.debug('Status: ' + res.getStatusCode());
System.debug('Body: ' + res.getBody());
