try {
    System.debug('--- PASO 1: GENERANDO COTIZACION ---');
    Tech_MueveteSeguroWrappers.QuotationRequest qReq = new Tech_MueveteSeguroWrappers.QuotationRequest();
    qReq.vehicleVersionId = 'bcfe6441-e3ac-4c33-b236-c21db67a340b'; // Altima 2022
    qReq.coverage = 'AMPLIA';
    qReq.insured = new Tech_MueveteSeguroWrappers.InsuredData();
    qReq.insured.name = 'Test E2E';
    qReq.insured.phone = '+527711154775';
    qReq.insured.zipCode = '43203';
    qReq.insured.birthDate = '1990-01-01';
    qReq.insured.gender = 'M';
    
    Tech_MueveteSeguroWrappers.QuotationResponse quoteRes = Tech_MueveteSeguroQuotationService.createQuotation(qReq);
    String qId = quoteRes.quotationId;
    System.debug('COTIZACION_OK: ' + qId);

    System.debug('--- PASO 2: SELECCIONANDO PLAN (HDI) ---');
    // Esta llamada es la que nos faltaba en el script anterior
    Tech_MueveteSeguroPlanService.selectPlan(qId, 'HDI');
    System.debug('SELECCION_OK');

    System.debug('--- PASO 3: EMITIENDO POLIZA ---');
    Map<String, Object> data = new Map<String, Object>();
    data.put('rfcKey', 'XAXX010101000');
    data.put('serialNumber', '3N1AB1AP0NL123456');
    data.put('phone', '+527711154775');
    data.put('birthdate', '1990-01-01');
    data.put('paternalSurname', 'Test');
    data.put('maternalSurname', 'E2E');
    data.put('fullName', 'Usuario');
    data.put('street', 'Calle Prueba 123');
    data.put('occupation', 'Empleado');
    data.put('maritalStatus', 'S');

    Tech_MueveteSeguroWrappers.PolicyResponse polRes = Tech_MueveteSeguroPolicyService.submitInsuredData(qId, data);
    
    System.debug('--- EXITO TOTAL ---');
    System.debug('POLIZA_ID: ' + polRes.policyId);
    System.debug('PAYMENT_LINK: ' + polRes.paymentUrl);

} catch (Exception e) {
    System.debug('ERROR_E2E: ' + e.getMessage());
}