/**
 * @description Acción Invocable para Agentforce: Genera una cotización de seguros de auto.
 * Paso 2 de 6 en el flujo de seguros.
 */
public class Tech_CreateAutoQuotation {

    public class QuotationInput {
        @InvocableVariable(label='ID de Version del Vehiculo' description='El identificador tecnico de la version del auto elegida en el paso 1.' required=true)
        public String vehicleVersionId;
        
        @InvocableVariable(label='Cobertura' description='El tipo de proteccion deseada. Los valores validos son: AMPLIA, LIMITADA o RC (Responsabilidad Civil).' required=true)
        public String coverage;
        
        @InvocableVariable(label='Nombre Completo' description='El nombre de pila y apellidos del interesado en el seguro.' required=true)
        public String fullName;
        
        @InvocableVariable(label='Telefono' description='El numero celular o local de contacto del usuario.' required=true)
        public String phone;
        
        @InvocableVariable(label='Codigo Postal' description='El CP de 5 digitos de la zona donde circula el vehiculo.' required=true)
        public String zipCode;
        
        @InvocableVariable(label='Fecha de Nacimiento (AAAA-MM-DD)' description='La fecha de nacimiento del conductor en formato estandar Año-Mes-Dia.' required=true)
        public String birthDate;
        
        @InvocableVariable(label='Genero (M/F)' description='El sexo biologico del conductor para calculo de riesgo: M para Masculino, F para Femenino.' required=true)
        public String gender;

        @InvocableVariable(label='Email' description='La direccion de correo electronico para enviar la cotización formal.')
        public String email;
    }

    public class QuotationOutput {
        @InvocableVariable(label='ID de Cotizacion' description='El identificador unico de la cotización generada en el sistema de Ollin.')
        public String quotationId;
        
        @InvocableVariable(label='Resultados por Aseguradora' description='Lista de opciones de precio y paquetes devueltos por aseguradoras como GNP, HDI, Mapfre, etc.')
        public List<Tech_MueveteSeguroWrappers.InsurerResult> results;
        
        @InvocableVariable(label='Mensaje de Error' description='Explicacion clara si no se pudieron obtener precios de la API.')
        public String errorMessage;
    }

    @InvocableMethod(label='Tech: Generar Cotizacion de Auto' description='Accion obligatoria para el Paso 2. Envia los datos personales del usuario para obtener precios reales y comparativos entre diferentes aseguradoras.')
    public static List<QuotationOutput> execute(List<QuotationInput> inputs) {
        List<QuotationOutput> outputs = new List<QuotationOutput>();
        for (QuotationInput input : inputs) {
            QuotationOutput out = new QuotationOutput();
            try {
                Tech_MueveteSeguroWrappers.QuotationRequest req = new Tech_MueveteSeguroWrappers.QuotationRequest();
                req.vehicleVersionId = input.vehicleVersionId;
                req.coverage = input.coverage;
                
                Tech_MueveteSeguroWrappers.InsuredData ins = new Tech_MueveteSeguroWrappers.InsuredData();
                ins.name = input.fullName;
                ins.phone = input.phone;
                ins.zipCode = input.zipCode;
                ins.birthDate = input.birthDate;
                ins.gender = input.gender;
                ins.email = input.email;
                req.insured = ins;

                Tech_MueveteSeguroWrappers.QuotationResponse res = Tech_MueveteSeguroQuotationService.createQuotation(req);
                out.quotationId = res.quotationId;
                out.results = res.results;
            } catch (Exception e) {
                out.errorMessage = e.getMessage();
            }
            outputs.add(out);
        }
        return outputs;
    }
}