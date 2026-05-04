try {
    System.debug('--- INICIO DE CONSULTA DE CATALOGOS ---');
    
    // 1. Consultar Años
    List<Integer> years = Tech_MueveteSeguroCatalogService.getYears();
    System.debug('RESULT_YEARS: ' + years);
    
    if(years != null && !years.isEmpty()) {
        // 2. Consultar Marcas para el primer año de la lista
        String testYear = String.valueOf(years[0]);
        List<Tech_MueveteSeguroWrappers.CatalogItem> brands = Tech_MueveteSeguroCatalogService.getBrands(testYear);
        System.debug('RESULT_BRANDS_FOR_' + testYear + ': ' + (brands != null ? String.valueOf(brands.size()) : 'null'));
    } else {
        System.debug('RESULT_YEARS: La lista de años esta vacia o es nula.');
    }
    
    System.debug('--- FIN DE CONSULTA DE CATALOGOS ---');
} catch(Exception e) {
    System.debug('CATALOG_ERROR: ' + e.getMessage());
}