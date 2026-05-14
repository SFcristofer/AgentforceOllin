/**
 * @description Clase que agrupa todas las estructuras de datos (DTOs) de la integración.
 * Corregida para compatibilidad con Agentforce (sin getters/setters en InvocableVariables).
 */
public class Tech_MueveteSeguroWrappers {

    public class CatalogItem {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
    }

    /**
     * @description DTO para cotización de seguros de vida.
     */
    public class LifeQuoteRequest {
        public String birthDate;
        public String gender;
        public String zipCode;
        public Boolean isSmoker;
        public Decimal desiredAmount;
        public String objective;
        public String term;
    }

    /**
     * @description Resultado de cotización de vida.
     */
    public class LifeQuoteResult {
        @AuraEnabled public String insurer;
        @AuraEnabled public String planName;
        @AuraEnabled public Decimal monthlyPremium;
        @AuraEnabled public Decimal annualPremium;
        @AuraEnabled public String coverageDetails;
    }

    public class CatalogListResponse {
        @AuraEnabled public List<CatalogItem> items;
        @AuraEnabled public List<Integer> yearItems;
    }

    public class InsuredData {
        @AuraEnabled public String name;
        @AuraEnabled public String phone;
        @AuraEnabled public String zipCode;
        @AuraEnabled public String birthDate;
        @AuraEnabled public String gender;
        @AuraEnabled public String email;
    }

    public class QuotationRequest {
        @InvocableVariable public String vehicleVersionId;
        @InvocableVariable public String coverage;
        @InvocableVariable public InsuredData insured;
    }

    public class PlanPackage {
        @AuraEnabled public String planId;
        @AuraEnabled public String planName;
        @AuraEnabled public Decimal totalAmount;
    }

    public class InsurerResult {
        @AuraEnabled public String insurer;
        @AuraEnabled public List<PlanPackage> packages;
    }

    public class QuotationResponse {
        @AuraEnabled public String quotationId;
        @AuraEnabled public String expiresAt;
        @AuraEnabled public List<InsurerResult> results;
    }

    public class Option {
        @InvocableVariable @AuraEnabled public String value;
        @InvocableVariable @AuraEnabled public String label;
    }

    public class RequiredField {
        @InvocableVariable @AuraEnabled public String field;
        @InvocableVariable @AuraEnabled public String type;
        @InvocableVariable @AuraEnabled public Boolean required;
        @InvocableVariable @AuraEnabled public String description;
        @InvocableVariable @AuraEnabled public String value;
        @InvocableVariable @AuraEnabled public List<Option> options;
    }

    public class SelectPlanResponse {
        @AuraEnabled public List<RequiredField> requiredFields;
    }

    public class PolicyResponse {
        @AuraEnabled public String policyId;
        @AuraEnabled public String paymentUrl;
        @AuraEnabled public String status;
        @AuraEnabled public String policyNumber;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String expiresAt;
        @AuraEnabled public String downloadUrl;
    }
}