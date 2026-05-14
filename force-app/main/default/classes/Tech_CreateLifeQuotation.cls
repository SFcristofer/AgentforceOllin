/**
 * @description Acción Invocable para Agentforce: Genera cotizaciones de Seguros de Vida.
 * Utiliza variables de salud y hábitos para el cálculo de primas.
 */
public class Tech_CreateLifeQuotation {

    public class LifeInput {
        @InvocableVariable(label='Nombre Completo' description='Nombre y apellidos del asegurado para el registro del lead.' required=true)
        public String fullName;

        @InvocableVariable(label='Teléfono' description='Número telefónico de contacto a 10 dígitos.' required=true)
        public String phone;

        @InvocableVariable(label='Código Postal' description='Código postal de residencia para determinar zona de riesgo.' required=true)
        public String zipCode;

        @InvocableVariable(label='Fecha de Nacimiento (AAAA-MM-DD)' description='Indispensable para calcular la edad técnica actuarial. Formato: YYYY-MM-DD.' required=true)
        public String birthDate;

        @InvocableVariable(label='Género (M/F)' description='Género biológico (M para Masculino, F para Femenino) para cálculo de prima.' required=true)
        public String gender;

        @InvocableVariable(label='¿Es Fumador? (true/false)' description='Dato crítico de salud. true si el cliente ha fumado en los últimos 12 meses.' required=true)
        public Boolean isSmoker;

        @InvocableVariable(label='Aportación Mensual Deseada' description='Monto en moneda nacional (MXN) que el cliente desea ahorrar o pagar mensualmente.' required=true)
        public Decimal monthlyContribution;

        @InvocableVariable(label='Objetivo (Retiro, Ahorro, Protección)' description='Meta principal del seguro: Retiro (jubilación), Ahorro (metas financieras) o Protección (fallecimiento).' required=true)
        public String objective;

        @InvocableVariable(label='Plazo en años' description='Número de años que el cliente desea mantener el plan de protección y ahorro.' required=true)
        public String term;
    }

    public class LifeOutput {
        @InvocableVariable(label='ID de Cotización' description='Identificador único de la cotización generada en el motor de Ollin.')
        public String quotationId;

        @InvocableVariable(label='Resultados de Aseguradoras' description='Lista de opciones de seguros de vida con precios, planes y beneficios desglosados.')
        public List<Tech_MueveteSeguroWrappers.InsurerResult> results;

        @InvocableVariable(label='Mensaje de Error' description='Si la operación falla, este campo contiene la razón técnica del error.')
        public String errorMessage;
    }

    @InvocableMethod(label='Tech: Cotizar Seguro de Vida' description='Genera opciones de precios de seguros de vida basadas en edad, salud y ahorro.')
    public static List<LifeOutput> execute(List<LifeInput> inputs) {
        List<LifeOutput> outputs = new List<LifeOutput>();
        
        for (LifeInput input : inputs) {
            LifeOutput out = new LifeOutput();
            try {
                Tech_MueveteSeguroWrappers.LifeQuoteRequest lifeReq = new Tech_MueveteSeguroWrappers.LifeQuoteRequest();
                lifeReq.birthDate = input.birthDate;
                lifeReq.gender = input.gender;
                lifeReq.zipCode = input.zipCode;
                lifeReq.isSmoker = input.isSmoker;
                lifeReq.desiredAmount = input.monthlyContribution;
                lifeReq.objective = input.objective;
                lifeReq.term = input.term;

                Tech_MueveteSeguroWrappers.QuotationResponse res = Tech_MueveteSeguroLifeService.getLifeQuotes(lifeReq, input.fullName, input.phone);
                
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