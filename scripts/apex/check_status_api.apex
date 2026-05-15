HttpRequest req = new HttpRequest();
req.setEndpoint('callout:MueveteSeguro_Bot_API/bot/quotation/status');
req.setMethod('GET');
HttpResponse res = new Http().send(req);
System.debug('STATUS_API_BODY: ' + res.getBody());
