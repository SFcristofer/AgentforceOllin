try {
    System.debug('--- PASO 1: CONSULTANDO MARCAS 2022 ---');
    List<Tech_MueveteSeguroWrappers.CatalogItem> brands = Tech_MueveteSeguroCatalogService.getBrands('2022');
    String nissanId = '';
    for(Tech_MueveteSeguroWrappers.CatalogItem b : brands) { if(b.name.contains('NISSAN')) nissanId = b.id; }
    System.debug('NISSAN_ID: ' + nissanId);

    System.debug('--- PASO 2: CONSULTANDO MODELOS NISSAN 2022 ---');
    List<Tech_MueveteSeguroWrappers.CatalogItem> models = Tech_MueveteSeguroCatalogService.getModels('2022', nissanId);
    String altimaId = '';
    for(Tech_MueveteSeguroWrappers.CatalogItem m : models) { if(m.name.contains('ALTIMA')) altimaId = m.id; }
    System.debug('ALTIMA_ID: ' + altimaId);

    System.debug('--- PASO 3: CONSULTANDO VERSIONES ALTIMA 2022 ---');
    List<Tech_MueveteSeguroWrappers.CatalogItem> versions = Tech_MueveteSeguroCatalogService.getVersions('2022', altimaId);
    System.debug('VERSION_SAMPLE: ' + (versions != null && versions.size() > 0 ? versions[0].name : 'null'));

    System.debug('--- PASO 4: INTENTANDO COTIZACION REAL ---');
    Tech_MueveteSeguroWrappers.QuotationRequest req = new Tech_MueveteSeguroWrappers.QuotationRequest();
    req.vehicleVersionId = versions[0].id;
    req.coverage = 'AMPLIA';
    req.insured = new Tech_MueveteSeguroWrappers.InsuredData();
    req.insured.name = 'Prueba Barrido';
    req.insured.phone = '+527711154775';
    req.insured.zipCode = '43203';
    req.insured.birthDate = '1995-10-10';
    req.insured.gender = 'M';
    
    Tech_MueveteSeguroWrappers.QuotationResponse quoteRes = Tech_MueveteSeguroQuotationService.createQuotation(req);
    System.debug('QUOTE_SUCCESS: ID ' + quoteRes.quotationId + ' - Aseguradoras: ' + quoteRes.results.size());

} catch (Exception e) {
    System.debug('BARRIDO_ERROR: ' + e.getMessage());
}