// 1. Obtener Cotización Base
Tech_MueveteSeguroWrappers.QuotationRequest req = new Tech_MueveteSeguroWrappers.QuotationRequest();
req.vehicleVersionId = 'bcfe6441-e3ac-4c33-b236-c21db67a340b';
req.coverage = 'AMPLIA';
req.insured = new Tech_MueveteSeguroWrappers.InsuredData();
req.insured.name = 'Test User';
req.insured.phone = '+527711154775';
req.insured.zipCode = '43203';
req.insured.birthDate = '1990-01-01';
req.insured.gender = 'M';

try {
    Tech_MueveteSeguroWrappers.QuotationResponse quoteRes = Tech_MueveteSeguroQuotationService.createQuotation(req);
    String qId = quoteRes.quotationId;
    System.debug('TECH_TEST: Cotizacion Exitosa ID: ' + qId);

    // 2. Probar Emisión por Aseguradora
    String[] insurers = new String[]{'HDI', 'ANA', 'GNP'};
    Map<String, Object> data = new Map<String, Object>();
    data.put('rfcKey', 'XAXX010101000');
    data.put('serialNumber', 'ABCDE123456789012');
    data.put('phone', '+527711154775');
    data.put('birthdate', '1990-01-01');
    data.put('paternalSurname', 'Test');
    data.put('maternalSurname', 'User');
    data.put('fullName', 'Test');

    for(String ins : insurers) {
        try {
            System.debug('TECH_TEST: Probando emision con ' + ins + '...');
            Tech_MueveteSeguroPolicyService.submitInsuredData(qId, data);
            System.debug('TECH_TEST: [EXITO] ' + ins + ' esta funcionando.');
        } catch (Exception e) {
            System.debug('TECH_TEST: [FALLO] ' + ins + ': ' + e.getMessage());
        }
    }
} catch (Exception e) {
    System.debug('TECH_TEST: Error general de API: ' + e.getMessage());
}