// 1. Obtener Cotización para Chevrolet Tahoe 2019
Tech_MueveteSeguroWrappers.QuotationRequest req = new Tech_MueveteSeguroWrappers.QuotationRequest();
// ID de Versión para Tahoe LT 2019 (obtenido de logs previos)
req.vehicleVersionId = '927e7c23-02c7-4054-84d0-fe98b53682f0'; 
req.coverage = 'AMPLIA';
req.insured = new Tech_MueveteSeguroWrappers.InsuredData();
req.insured.name = 'Prueba Ana';
req.insured.phone = '+525512345678';
req.insured.zipCode = '06000'; // CP CDMX
req.insured.birthDate = '1985-05-15';
req.insured.gender = 'F';

try {
    System.debug('TECH_ANA_TEST: Iniciando cotizacion...');
    Tech_MueveteSeguroWrappers.QuotationResponse quoteRes = Tech_MueveteSeguroQuotationService.createQuotation(req);
    String qId = quoteRes.quotationId;
    System.debug('TECH_ANA_TEST: Cotizacion Generada: ' + qId);

    // 2. Intentar Selección y Emisión con ANA
    Map<String, Object> data = new Map<String, Object>();
    data.put('rfcKey', 'XAXX010101000');
    data.put('serialNumber', '1GNSKBEKC0JR12345'); // VIN Chevrolet Tahoe
    data.put('phone', '+525512345678');
    data.put('birthdate', '1985-05-15');
    data.put('email', 'ana_test@ollin.com.mx');
    data.put('street', 'Reforma 222');
    data.put('occupation', 'Profesionista');
    data.put('maritalStatus', 'S');
    data.put('paternalSurname', 'Prueba');
    data.put('maternalSurname', 'Ana');
    data.put('fullName', 'Maria');

    System.debug('TECH_ANA_TEST: Intentando emision con ANA...');
    Tech_MueveteSeguroWrappers.PolicyResponse res = Tech_MueveteSeguroPolicyService.submitInsuredData(qId, data);
    System.debug('TECH_ANA_TEST: [EXITO] Poliza Generada: ' + res.policyId);
    System.debug('TECH_ANA_TEST: URL Pago: ' + res.paymentUrl);

} catch (Exception e) {
    System.debug('TECH_ANA_TEST: [FALLO] El error persiste: ' + e.getMessage());
}