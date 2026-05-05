/**
 * @description Acción Invocable de Alta Eficiencia para Agentforce.
 * Permite al Agente verificar el estado real del pago y entregar la póliza final.
 * Paso 6 de 6 en el flujo de seguros Ollin.
 */
public class Tech_VerificarPago {

    public class StatusInput {
        @InvocableVariable(label='ID de Poliza' description='Identificador unico de la poliza obtenido en el paso de emision.' required=true)
        public String policyId;
    }

    public class StatusOutput {
        @InvocableVariable(label='Estado del Pago' description='Estado simplificado: PAGADO, PENDIENTE o RECHAZADO.')
        public String paymentStatus;

        @InvocableVariable(label='Numero de Poliza' description='El numero oficial generado por la aseguradora.')
        public String policyNumber;

        @InvocableVariable(label='Enlace de Descarga PDF' description='URL directa para que el usuario descargue su poliza.')
        public String downloadUrl;

        @InvocableVariable(label='Mensaje para el Usuario' description='Texto sugerido para que el Agente cierre la venta con elegancia.')
        public String feedbackMessage;

        @InvocableVariable(label='Es Exitoso' description='Indica si el proceso de consulta fue correcto.')
        public Boolean isSuccess;
    }

    @InvocableMethod(label='Tech: Verificar Pago' description='Consulta en tiempo real si el usuario ya realizo el pago y recupera los documentos finales.')
    public static List<StatusOutput> execute(List<StatusInput> inputs) {
        List<StatusOutput> outputs = new List<StatusOutput>();

        for (StatusInput input : inputs) {
            StatusOutput out = new StatusOutput();
            try {
                // Consultar a la API de Ollin a traves del Service
                Tech_MueveteSeguroWrappers.PolicyResponse res = Tech_MueveteSeguroPolicyService.getPolicyStatus(input.policyId);
                
                out.policyNumber = res.policyNumber;
                out.downloadUrl = res.downloadUrl;
                out.isSuccess = true;

                // Mapeo de estados para Agentforce
                if (res.status == 'approved') {
                    out.paymentStatus = 'PAGADO';
                    out.feedbackMessage = '¡Felicidades! Tu pago ha sido confirmado exitosamente. Tu número de póliza es ' + res.policyNumber + '. Puedes descargar tu documento aquí: ' + res.downloadUrl;
                } else if (res.status == 'pending_payment') {
                    out.paymentStatus = 'PENDIENTE';
                    out.feedbackMessage = 'Aún no visualizamos tu pago. Si ya lo realizaste, puede tardar unos segundos en reflejarse. ¿Gustas que verifique de nuevo en un momento?';
                } else if (res.status == 'refused') {
                    out.paymentStatus = 'RECHAZADO';
                    out.feedbackMessage = 'Lo sentimos, el pago ha sido rechazado por la plataforma. ¿Deseas intentar con otro método de pago o con otra aseguradora?';
                } else {
                    out.paymentStatus = 'DESCONOCIDO';
                    out.feedbackMessage = 'El estado actual es: ' + res.status + '. Por favor, mantente en línea.';
                }

            } catch (Exception e) {
                out.isSuccess = false;
                out.paymentStatus = 'ERROR';
                out.feedbackMessage = 'Hubo un inconveniente al consultar el estado: ' + e.getMessage();
            }
            outputs.add(out);
        }
        return outputs;
    }
}