System.debug('--- START API CHECK ---');
try {
    String insurers = MueveteSeguroService.getInsurers();
    System.debug('Insurers: ' + insurers);
    
    String coverages = MueveteSeguroService.getCoverages();
    System.debug('Coverages: ' + coverages);
} catch (Exception e) {
    System.debug('Error: ' + e.getMessage());
}
System.debug('--- END API CHECK ---');
