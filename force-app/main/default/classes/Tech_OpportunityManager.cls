public with sharing class Tech_OpportunityManager {
    
    public class OpportunityRequest {
        // --- CONTROL DE IDENTIDAD ---
        @InvocableVariable(required=true description='ID del Lead o Cuenta identificado. Es la llave de relación principal.')
        public Id recordId;
        
        @InvocableVariable(required=true description='Especificar si es "Cliente" o "Prospecto". Define si se vincula a AccountId o Prospecto__c.')
        public String clientType;
        
        @InvocableVariable(required=true description='Ramo técnico del seguro: Auto, Vida, GMM, PPR, Fianzas, etc. Mapea a Ramo__c.')
        public String ramo;
        
        @InvocableVariable(description='Nombre completo del cliente para nombrar la Oportunidad profesionalmente.')
        public String clientName;

        // --- ASPECTOS FINANCIEROS ---
        @InvocableVariable(description='Prima Total Anual o costo final de la póliza. Este valor llena el campo estándar Amount (Importe).')
        public Decimal amount;

        @InvocableVariable(description='Porcentaje de comisión pactado para Ollin. Mapea a PctComisionOllin__c.')
        public Decimal commissionPercent;

        @InvocableVariable(description='Suma Asegurada total. Al no existir campo en Oportunidad, se registra en la Ficha Técnica para el vendedor.')
        public Decimal sumAssured;

        @InvocableVariable(description='Aportación periódica estimada (para planes de ahorro/PPR). Se registra en la Ficha Técnica.')
        public Decimal estimatedContribution;

        // --- DATOS DEL RAMO: AUTO ---
        @InvocableVariable(description='Año de fabricación del vehículo. Mapea a Ano_vehiculo__c.')
        public Double vehicleYear;

        @InvocableVariable(description='Descripción completa: Marca, Modelo y Versión del vehículo. Mapea a Modelo__c.')
        public String vehicleModel;

        // --- PLAN Y COBERTURA ---
        @InvocableVariable(description='ID del Producto del catálogo de Salesforce. Mapea a Producto__c.')
        public Id productId;

        @InvocableVariable(description='Nombre del plan o cobertura para búsqueda automática si no hay ID.')
        public String planName;

        // --- PAGO Y VIGENCIA ---
        @InvocableVariable(description='Forma de pago elegida (Transferencia, Tarjeta, Domiciliación, etc.). Mapea a Metodo_Pago__c.')
        public String metodoPago;

        @InvocableVariable(description='Frecuencia de pago (Contado, Mensual, Trimestral, etc.). Mapea a Periodo_Pago__c.')
        public String periodoPago;

        @InvocableVariable(description='Número total de parcialidades o pagos. Mapea a Numero_Pagos__c.')
        public Double numeroPagos;

        @InvocableVariable(description='Fecha en que inicia la protección. Mapea a Fecha_Inicio_Vigencia__c.')
        public Date fechaInicio;

        @InvocableVariable(description='Fecha en que termina la protección. Mapea a Fecha_Fin_Vigencia__c.')
        public Date fechaFin;

        @InvocableVariable(description='Plazo o duración del seguro en números (ej: 12 meses). Mapea a Vigencia__c.')
        public Double vigencia;

        // --- DATOS DEL PERFIL (Ficha Técnica) ---
        @InvocableVariable(description='Edad del asegurado al momento de cotizar.')
        public Integer age;

        @InvocableVariable(description='Hábito de fuma del asegurado (Sí/No).')
        public String isSmoker;

        @InvocableVariable(description='Género del asegurado (Masculino/Femenino).')
        public String gender;

        @InvocableVariable(description='Fecha de nacimiento oficial del asegurado.')
        public Date birthDate;

        @InvocableVariable(description='Teléfono de contacto validado.')
        public String phone;

        // --- ADMINISTRATIVOS Y EXTERNOS ---
        @InvocableVariable(description='ID de cotización generado en el portal de la aseguradora. Mapea a Cotizacion_Externa_Id__c.')
        public String cotizacionExternaId;

        @InvocableVariable(description='Nombre de la aseguradora con la que el cliente está comparando. Mapea a Aseguradora_Competidora__c.')
        public String competidor;

        @InvocableVariable(description='Enlace directo a la carátula de la póliza o cotización. Mapea a URL_Poliza__c.')
        public String urlPoliza;

        @InvocableVariable(description='Tipo de origen (Digital, Consultivo, Promotoría). Mapea a Tipo_Originador__c.')
        public String tipoOriginador;

        @InvocableVariable(description='ID de la Institución/Cuenta corporativa relacionada. Mapea a Institucion__c.')
        public Id institucionId;

        @InvocableVariable(description='ID del Vendedor responsable. Mapea a Vendedor_A__c.')
        public Id vendedorId;

        @InvocableVariable(description='ID de la póliza anterior en caso de ser una renovación. Mapea a Poliza_Renovar__c.')
        public Id polizaRenovarId;

        @InvocableVariable(description='Comentarios adicionales o contexto de la conversación. Mapea a Notas_Vendedor__c.')
        public String technicalNotes;
    }

    public class OpportunityResult {
        @InvocableVariable public Boolean isSuccess = false;
        @InvocableVariable public Id opportunityId;
        @InvocableVariable public String message;
    }

    @InvocableMethod(label='Tech: Registro Integral de Oportunidad' description='Acción definitiva para crear oportunidades con mapeo 1 a 1 de todos los campos de Ollin Protección.')
    public static List<OpportunityResult> manageOpportunity(List<OpportunityRequest> requests) {
        List<OpportunityResult> results = new List<OpportunityResult>();
        
        for (OpportunityRequest req : requests) {
            OpportunityResult res = new OpportunityResult();
            
            try {
                Opportunity opp = new Opportunity();
                
                // 1. CONSTRUCCIÓN DEL NOMBRE
                String namePrefix = String.isNotBlank(req.ramo) ? req.ramo.toUpperCase() : 'SEGURO';
                String customer = String.isNotBlank(req.clientName) ? req.clientName : 'Cliente';
                opp.Name = namePrefix + ' - ' + customer + ' - ' + System.today().format();
                
                // 2. VÍNCULO DE IDENTIDAD
                if (req.clientType == 'Cliente' || (req.recordId != null && req.recordId.getSObjectType().getDescribe().getName() == 'Account')) {
                    opp.AccountId = req.recordId;
                } else {
                    opp.Prospecto__c = req.recordId;
                }

                // 3. MAPEO FINANCIERO Y ESTÁNDAR
                opp.Amount = (req.amount != null) ? req.amount : 0;
                opp.StageName = 'Propuesta enviada / presentada';
                opp.CloseDate = System.today().addDays(30);
                opp.Probability = 50;
                opp.LeadSource = 'Agentforce';

                // 4. MAPEO DE CAMPOS PERSONALIZADOS (1 a 1)
                opp.Ramo__c = req.ramo;
                opp.PctComisionOllin__c = req.commissionPercent;
                opp.Metodo_Pago__c = req.metodoPago;
                opp.Periodo_Pago__c = req.periodoPago;
                opp.Numero_Pagos__c = req.numeroPagos;
                opp.Fecha_Inicio_Vigencia__c = (req.fechaInicio != null) ? req.fechaInicio : System.today();
                opp.Fecha_Fin_Vigencia__c = req.fechaFin;
                opp.Vigencia__c = req.vigencia;
                
                // Autos
                opp.Ano_vehiculo__c = req.vehicleYear;
                opp.Modelo__c = req.vehicleModel;

                // Externos y Admin
                opp.Cotizacion_Externa_Id__c = req.cotizacionExternaId;
                opp.Aseguradora_Competidora__c = req.competidor;
                opp.URL_Poliza__c = req.urlPoliza;
                opp.Tipo_Originador__c = String.isNotBlank(req.tipoOriginador) ? req.tipoOriginador : 'Digital';
                
                // --- ARQUITECTURA DE PRODUCTO TOTALMENTE SINCRONIZADA ---
                Id finalProductId = req.productId;

                if (finalProductId == null) {
                    // Si no hay ID, usamos nuestro motor de mapeo inteligente por Ramo para obtener el ID de Producto real
                    Product2 officialProduct = getOfficialProduct(req.ramo, req.planName);
                    if (officialProduct != null) {
                        finalProductId = officialProduct.Id;
                    }
                }

                // Asignación final al Lookup de Producto únicamente
                opp.Producto__c = finalProductId;

                // Relaciones restantes
                opp.Institucion__c = req.institucionId;
                opp.Vendedor_A__c = (req.vendedorId != null) ? req.vendedorId : 'a0Qct00000Fj2UrEAJ';
                opp.Poliza_Renovar__c = req.polizaRenovarId;

                // 5. GENERACIÓN DE FICHA TÉCNICA INTEGRAL (Para Notas_Vendedor__c)
                String ficha = '--- RESUMEN DE IDENTIDAD ---\n';
                if (String.isNotBlank(req.phone)) ficha += 'Teléfono: ' + req.phone + '\n';
                if (req.birthDate != null) ficha += 'F. Nacimiento: ' + req.birthDate.format() + '\n';
                if (req.age != null) ficha += 'Edad: ' + req.age + '\n';
                if (String.isNotBlank(req.gender)) ficha += 'Género: ' + req.gender + '\n';
                if (String.isNotBlank(req.isSmoker)) ficha += 'Fuma: ' + req.isSmoker + '\n';
                
                ficha += '\n--- ESPECIFICACIONES TÉCNICAS ---\n';
                if (req.sumAssured != null) ficha += 'Suma Asegurada: $' + req.sumAssured + '\n';
                if (req.estimatedContribution != null) ficha += 'Aportación: $' + req.estimatedContribution + '\n';
                
                if (String.isNotBlank(req.technicalNotes)) {
                    ficha += '\n--- CONTEXTO DE CONVERSACIÓN ---\n' + req.technicalNotes;
                }
                
                opp.Notas_Vendedor__c = ficha;
                
                String descPrefix = 'Oportunidad orquestada por IA Agentforce - Ramo: ' + req.ramo;
                opp.Description = String.isNotBlank(req.technicalNotes) ? descPrefix + '\nContexto: ' + req.technicalNotes : descPrefix;

                insert opp;

                res.isSuccess = true;
                res.opportunityId = opp.Id;
                res.message = 'Registro exitoso en ' + req.ramo;
                
            } catch (Exception e) {
                res.isSuccess = false;
                res.message = 'Fallo en Registro: ' + e.getMessage();
            }
            results.add(res);
        }
        return results;
    }

    /**
     * @description Obtiene el registro oficial de Producto basado en el ramo y subproducto.
     * Devuelve el objeto completo para acceder al Id y al Name oficial.
     */
    private static Product2 getOfficialProduct(String ramo, String subproducto) {
        if (String.isBlank(ramo)) return null;

        String searchCode = '';
        String cleanRamo = ramo.toUpperCase();
        String cleanSub = String.isNotBlank(subproducto) ? subproducto.toUpperCase() : '';

        // 1. DETERMINACIÓN DEL CÓDIGO POR RAMO (ESTRICTO)
        if (cleanRamo.contains('AUTO') || cleanRamo.contains('VEHICULO')) {
            if (cleanSub.contains('AMPLIA') || cleanSub.contains('AMPLIO')) searchCode = 'AUTO-AMPLIA';
            else if (cleanSub.contains('LIMITADA') || cleanSub.contains('LIMITADO')) searchCode = 'AUTO-LIMITADA';
            else if (cleanSub.contains('RC') || cleanSub.contains('RESPONSABILIDAD')) searchCode = 'AUTO-RC';
            else searchCode = 'AUTO-AMPLIA'; 
        } 
        else if (cleanRamo.contains('VIDA')) {
            searchCode = 'VIDA-001';
        }
        else if (cleanRamo.contains('GMM') || cleanRamo.contains('MEDIC') || cleanRamo.contains('GASTOS')) {
            searchCode = 'GMM-001';
        }
        else if (cleanRamo.contains('PPR') || cleanRamo.contains('RETIRO') || cleanRamo.contains('AHORRO')) {
            searchCode = 'PPR-001';
        }
        else if (cleanRamo.contains('FIANZA')) {
            searchCode = 'FZA-CUMP';
        }

        if (String.isBlank(searchCode)) return null;

        try {
            List<Product2> prods = [SELECT Id, Name FROM Product2 WHERE ProductCode = :searchCode AND IsActive = true LIMIT 1];
            return prods.isEmpty() ? null : prods[0];
        } catch (Exception e) {
            return null;
        }
    }
}
