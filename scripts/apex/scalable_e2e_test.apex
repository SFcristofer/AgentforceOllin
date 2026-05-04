try {
    System.debug('--- INICIO PRUEBA ESCALABLE ---');
    
    // PASO 1: COTIZACIÓN
    Tech_MueveteSeguroWrappers.QuotationRequest qReq = new Tech_MueveteSeguroWrappers.QuotationRequest();
    qReq.vehicleVersionId = 'bcfe6441-e3ac-4c33-b236-c21db67a340b';
    qReq.coverage = 'AMPLIA';
    qReq.insured = new Tech_MueveteSeguroWrappers.InsuredData();
    qReq.insured.name = 'Prueba Escalable';
    qReq.insured.phone = '+527711154775';
    qReq.insured.zipCode = '43203';
    qReq.insured.birthDate = '1995-10-10';
    qReq.insured.gender = 'M';
    
    Tech_MueveteSeguroWrappers.QuotationResponse quoteRes = Tech_MueveteSeguroQuotationService.createQuotation(qReq);
    String qId = quoteRes.quotationId;
    System.debug('1. COTIZACION GENERADA: ' + qId);

    // PASO 2: SELECCIÓN Y OBTENCIÓN DE OPCIONES DINÁMICAS
    // Esto es lo que el Agente hace en el Paso 3
    List<Tech_MueveteSeguroWrappers.RequiredField> fields = Tech_MueveteSeguroPlanService.selectPlan(qId, 'HDI');
    System.debug('2. SELECCION Y CAMPOS OBTENIDOS');

    // PASO 3: EMISIÓN CON MAPEO DINÁMICO
    Tech_SubmitInsuredData.PolicyInput pInput = new Tech_SubmitInsuredData.PolicyInput();
    pInput.quotationId = qId;
    pInput.rfc = 'XAXX010101000';
    pInput.vin = '3N1AB1AP0NL123456';
    pInput.phone = '+527711154775';
    pInput.birthDate = '1995-10-10';
    pInput.firstName = 'Usuario';
    pInput.paternalSurname = 'Escalable';
    pInput.maternalSurname = 'Test';
    pInput.street = 'Calle Falsa 123';
    
    // Aquí simulamos que el usuario escribió el texto amigable
    pInput.occupation = 'Empleado'; 
    
    // PASAMOS LAS OPCIONES DINÁMICAS PARA EL CRUCE
    pInput.allRequiredFields = fields;

    List<Tech_SubmitInsuredData.PolicyInput> inputs = new List<Tech_SubmitInsuredData.PolicyInput>{ pInput };
    List<Tech_SubmitInsuredData.PolicyOutput> outputs = Tech_SubmitInsuredData.execute(inputs);

    if (outputs[0].errorMessage == null) {
        System.debug('--- EXITO TOTAL ---');
        System.debug('POLIZA_ID: ' + outputs[0].policyId);
        System.debug('PAYMENT_LINK: ' + outputs[0].paymentUrl);
    } else {
        System.debug('--- ERROR EN EMISION ---');
        System.debug('MENSAJE: ' + outputs[0].errorMessage);
    }

} catch (Exception e) {
    System.debug('ERROR_SISTEMA: ' + e.getMessage());
}