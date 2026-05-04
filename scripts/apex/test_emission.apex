// Simulamos los datos exactos del log del usuario
Map<String, Object> data = new Map<String, Object>();
data.put('rfcKey', 'COCC9701295V4');
data.put('serialNumber', '3N1AB1AP0NL123456');
data.put('phone', '7711154775');
data.put('birthdate', '1997-01-26');
data.put('email', 'example@example.com');
data.put('street', 'Pachuca de Soto Juan Cedoria');
data.put('occupation', 'Empleado');
data.put('maritalStatus', 'S');
data.put('paternalSurname', 'Contreras');
data.put('maternalSurname', 'Ciriaco');
data.put('fullName', 'Cristofer');

String quotationId = '434c9159-b879-4daa-a976-06dc819e106b';

try {
    Tech_MueveteSeguroWrappers.PolicyResponse res = Tech_MueveteSeguroPolicyService.submitInsuredData(quotationId, data);
    System.debug('TECH_EMISSION_SUCCESS: ' + JSON.serialize(res));
} catch (Exception e) {
    System.debug('TECH_EMISSION_ERROR: ' + e.getMessage());
}