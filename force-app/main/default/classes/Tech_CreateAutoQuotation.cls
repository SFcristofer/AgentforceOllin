/**
 * @description Acción Invocable para Agentforce: Genera una cotización de seguros de auto.
 * Paso 2 de 6 en el flujo de seguros.
 */
public class Tech_CreateAutoQuotation {

    public class QuotationInput {
        @InvocableVariable(label='ID de Versión del Vehículo' required=true)
        public String vehicleVersionId;
        
        @InvocableVariable(label='Cobertura' description='AMPLIA, LIMITADA o RC' required=true)
        public String coverage;
        
        @InvocableVariable(label='Nombre Completo' required=true)
        public String fullName;
        
        @InvocableVariable(label='Teléfono' required=true)
        public String phone;
        
        @InvocableVariable(label='Código Postal' required=true)
        public String zipCode;
        
        @InvocableVariable(label='Fecha de Nacimiento (AAAA-MM-DD)' required=true)
        public String birthDate;
        
        @InvocableVariable(label='Género (M/F)' required=true)
        public String gender;

        @InvocableVariable(label='Email (Opcional)')
        public String email;
    }

    public class QuotationOutput {
        @InvocableVariable(label='ID de Cotización')
        public String quotationId;
        
        @InvocableVariable(label='Resultados por Aseguradora')
        public List<Tech_MueveteSeguroWrappers.InsurerResult> results;
        
        @InvocableVariable(label='Mensaje de Error')
        public String errorMessage;
    }

    @InvocableMethod(label='Tech: Generar Cotización de Auto' description='Envía los datos del asegurado y recibe opciones de precios por aseguradora.')
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