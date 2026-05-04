// Usamos el ID de cotización exitoso del paso anterior
String qId = '017851fa-f6bb-48fb-9c7a-35a0607cf66a';

Map<String, Object> data = new Map<String, Object>();
data.put('rfcKey', 'XAXX010101000');
data.put('serialNumber', '3N1AB1AP0NL123456'); // VIN Nissan
data.put('phone', '+527711154775');
data.put('birthdate', '1995-10-10');
data.put('email', 'pago_test@ollin.com.mx');
data.put('street', 'Av. Insurgentes 1234');
data.put('occupation', 'Empleado');
data.put('maritalStatus', 'S');
data.put('paternalSurname', 'Barrido');
data.put('maternalSurname', 'Prueba');
data.put('fullName', 'Juan');

try {
    System.debug('--- INTENTANDO EMISIÓN FINAL ---');
    Tech_MueveteSeguroWrappers.PolicyResponse res = Tech_MueveteSeguroPolicyService.submitInsuredData(qId, data);
    
    if(res != null) {
        System.debug('EMISION_SUCCESS: ID Poliza ' + res.policyId);
        System.debug('PAYMENT_URL: ' + res.paymentUrl);
        System.debug('MONTO: ' + res.amount);
    }
} catch (Exception e) {
    System.debug('EMISION_ERROR: ' + e.getMessage());
}