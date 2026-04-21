/**
 * CobranzaMessaging — helper para enviar mensajes transaccionales de Cobranza/Renovación.
 *
 * Soporta:
 *  - Email transaccional (Messaging.SingleEmailMessage) sin plantilla — cuerpo inline.
 *  - Stub WhatsApp vía Digital Engagement (publica Platform Event WA_Outbound__e).
 *
 * El stub de WhatsApp queda listo para que, cuando Technovalue configure el canal
 * en Digital Engagement, el Platform Event se transforme en MessagingSession
 * vía Flow (MessagingSession.createMessage). Mientras tanto, registra en debug.
 *
 * @author Ollin Protección — 2026-04-19 (v6)
 */
public with sharing class CobranzaMessaging {

    /** Envía un email simple con asunto/cuerpo HTML a un destinatario. */
    public static void sendEmail(Id contactOrAccountId, String toAddress, String subject, String htmlBody) {
        if (String.isBlank(toAddress)) return;
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setToAddresses(new List<String>{ toAddress });
        msg.setSubject(subject);
        msg.setHtmlBody(htmlBody);
        msg.setSaveAsActivity(true);
        if (contactOrAccountId != null) {
            msg.setWhatId(contactOrAccountId);
        }
        try {
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ msg });
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'CobranzaMessaging.sendEmail failed: ' + e.getMessage());
        }
    }

    /**
     * Stub WhatsApp — emite un Platform Event que Digital Engagement consumirá.
     * Hasta que WA_Outbound__e esté creado, solo registra en debug.
     */
    public static void sendWhatsApp(String toPhone, String textBody) {
        if (String.isBlank(toPhone) || String.isBlank(textBody)) return;
        System.debug(LoggingLevel.INFO,
            'CobranzaMessaging.sendWhatsApp — STUB — to=' + toPhone + ' body=' + textBody);
        // TODO: cuando exista WA_Outbound__e:
        //   EventBus.publish(new WA_Outbound__e(To_Phone__c = toPhone, Body__c = textBody));
    }

    /** Resuelve email del cliente desde un Seguro__c. */
    public static String emailFromSeguro(Seguro__c s) {
        if (s == null || s.Cliente__c == null) return null;
        Account a = [SELECT PersonEmail, PersonMobilePhone FROM Account WHERE Id = :s.Cliente__c LIMIT 1];
        return a != null ? a.PersonEmail : null;
    }

    /** Resuelve teléfono del cliente desde un Seguro__c. */
    public static String phoneFromSeguro(Seguro__c s) {
        if (s == null || s.Cliente__c == null) return null;
        Account a = [SELECT PersonEmail, PersonMobilePhone FROM Account WHERE Id = :s.Cliente__c LIMIT 1];
        return a != null ? a.PersonMobilePhone : null;
    }
}