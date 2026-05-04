// Primero obtenemos el ID de Nissan
List<Tech_MueveteSeguroWrappers.CatalogItem> brands = Tech_MueveteSeguroCatalogService.getBrands('2022');
String nissanId = '';
for(Tech_MueveteSeguroWrappers.CatalogItem b : brands) { if(b.name.contains('NISSAN')) nissanId = b.id; }

// Luego el ID de Altima
List<Tech_MueveteSeguroWrappers.CatalogItem> models = Tech_MueveteSeguroCatalogService.getModels('2022', nissanId);
String altimaId = '';
for(Tech_MueveteSeguroWrappers.CatalogItem m : models) { if(m.name.contains('ALTIMA')) altimaId = m.id; }

// Finalmente vemos qué traen las versiones
HttpResponse res = Tech_MueveteSeguroBase.sendRequest('GET', '/bot/catalog/versions?year=2022&modelId=' + altimaId, null);
System.debug('TECH_RAW_VERSIONS_JSON: ' + res.getBody());