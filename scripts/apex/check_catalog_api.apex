try {
    // 1. Probar Años
    System.debug('TECH_CATALOG_CHECK: Consultando años...');
    List<Integer> years = Tech_MueveteSeguroCatalogService.getYears();
    System.debug('TECH_CATALOG_CHECK: [EXITO] Años recibidos: ' + years.size());

    // 2. Probar Marcas para 2022
    System.debug('TECH_CATALOG_CHECK: Consultando marcas para 2022...');
    List<Tech_MueveteSeguroWrappers.CatalogItem> brands = Tech_MueveteSeguroCatalogService.getBrands('2022');
    System.debug('TECH_CATALOG_CHECK: [EXITO] Marcas recibidas: ' + brands.size());

} catch (Exception e) {
    System.debug('TECH_CATALOG_CHECK: [FALLO] Error en catalogos: ' + e.getMessage());
}