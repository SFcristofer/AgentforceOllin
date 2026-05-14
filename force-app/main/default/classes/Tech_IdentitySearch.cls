public with sharing class Tech_IdentitySearch {
    
    public class IdentityRequest {
        @InvocableVariable(required=true description='Email del usuario para buscar en el sistema')
        public String email;
    }

    public class IdentityResult {
        @InvocableVariable(description='Indica si se encontró un registro existente')
        public Boolean isExisting = false;
        
        @InvocableVariable(description='Nombre completo encontrado')
        public String foundName;
        
        @InvocableVariable(description='ID del registro (Lead o Account)')
        public Id recordId;
        
        @InvocableVariable(description='Tipo de registro: Cliente o Prospecto')
        public String clientType;

        // --- NUEVOS CAMPOS PARA MEMORIA DE AGENTFORCE ---
        @InvocableVariable(description='Teléfono o Celular recuperado')
        public String phone;

        @InvocableVariable(description='RFC recuperado')
        public String rfc;

        @InvocableVariable(description='Género recuperado')
        public String gender;

        @InvocableVariable(description='Fecha de Nacimiento')
        public Date birthDate;

        @InvocableVariable(description='Indica si fuma (Sí/No)')
        public String isSmoker;
    }

    @InvocableMethod(label='Tech: Buscar Identidad por Email' description='Busca en Contacts y Leads por email para identificar clientes existentes y recuperar su perfil.')
    public static List<IdentityResult> searchIdentity(List<IdentityRequest> requests) {
        List<IdentityResult> results = new List<IdentityResult>();
        
        for (IdentityRequest req : requests) {
            IdentityResult res = new IdentityResult();
            
            if (String.isBlank(req.email)) {
                results.add(res);
                continue;
            }

            // 1. Prioridad: Buscar en Cuentas (PersonAccounts / Clientes)
            // Nota: PersonEmail y PersonMobilePhone son campos de Person Account
            List<Account> accounts = [SELECT Id, Name, PersonMobilePhone, RFC__c, Fecha_de_nacimiento__c 
                                    FROM Account 
                                    WHERE PersonEmail = :req.email AND IsPersonAccount = true 
                                    ORDER BY LastModifiedDate DESC LIMIT 1];
            
            if (!accounts.isEmpty()) {
                Account acc = accounts[0];
                res.isExisting = true;
                res.foundName = acc.Name;
                res.recordId = acc.Id;
                res.clientType = 'Cliente';
                res.phone = acc.PersonMobilePhone;
                res.rfc = acc.RFC__c;
                res.birthDate = acc.Fecha_de_nacimiento__c;
                // Gender/Smoker no suelen estar en Account estándar, pero si estuvieran se mapearían aquí
                results.add(res);
                continue;
            }

            // 2. Segunda opción: Buscar en Prospectos (Leads no convertidos)
            List<Lead> leads = [SELECT Id, Name, Phone, RFC__c, Genero__c, Fecha_de_nacimiento__c, Fuma__c 
                              FROM Lead 
                              WHERE Email = :req.email AND IsConverted = false 
                              ORDER BY LastModifiedDate DESC LIMIT 1];
            
            if (!leads.isEmpty()) {
                Lead l = leads[0];
                res.isExisting = true;
                res.foundName = l.Name;
                res.recordId = l.Id;
                res.clientType = 'Prospecto';
                res.phone = l.Phone;
                res.rfc = l.RFC__c;
                res.gender = l.Genero__c;
                res.birthDate = l.Fecha_de_nacimiento__c;
                res.isSmoker = (l.Fuma__c == true) ? 'Sí' : 'No';
                results.add(res);
                continue;
            }

            // No se encontró nada
            results.add(res);
        }
        
        return results;
    }
}
