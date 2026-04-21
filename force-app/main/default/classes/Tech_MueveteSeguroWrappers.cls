/**
 * @description Clase que agrupa todas las estructuras de datos (DTOs) de la integración.
 */
public class Tech_MueveteSeguroWrappers {

    public class CatalogItem {
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String name {get;set;}
    }

    public class CatalogListResponse {
        @AuraEnabled public List<CatalogItem> items {get;set;}
        @AuraEnabled public List<Integer> yearItems {get;set;}
    }

    public class InsuredData {
        @AuraEnabled public String name {get;set;}
        @AuraEnabled public String phone {get;set;}
        @AuraEnabled public String zipCode {get;set;}
        @AuraEnabled public String birthDate {get;set;}
        @AuraEnabled public String gender {get;set;}
        @AuraEnabled public String email {get;set;}
    }

    public class QuotationRequest {
        @AuraEnabled public String vehicleVersionId {get;set;}
        @AuraEnabled public String coverage {get;set;}
        @AuraEnabled public InsuredData insured {get;set;}
    }

    public class PlanPackage {
        @AuraEnabled public String planId {get;set;}
        @AuraEnabled public String planName {get;set;}
        @AuraEnabled public Decimal totalAmount {get;set;}
    }

    public class InsurerResult {
        @AuraEnabled public String insurer {get;set;}
        @AuraEnabled public List<PlanPackage> packages {get;set;}
    }

    public class QuotationResponse {
        @AuraEnabled public String quotationId {get;set;}
        @AuraEnabled public String expiresAt {get;set;}
        @AuraEnabled public List<InsurerResult> results {get;set;}
    }

    public class Option {
        @AuraEnabled public String value {get;set;}
        @AuraEnabled public String label {get;set;}
    }

    public class RequiredField {
        @AuraEnabled public String field {get;set;}
        @AuraEnabled public String type {get;set;}
        @AuraEnabled public Boolean required {get;set;}
        @AuraEnabled public String description {get;set;}
        @AuraEnabled public List<Option> options {get;set;}
    }

    public class SelectPlanResponse {
        @AuraEnabled public List<RequiredField> requiredFields {get;set;}
    }

    public class PolicyResponse {
        @AuraEnabled public String policyId {get;set;}
        @AuraEnabled public String paymentUrl {get;set;}
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String policyNumber {get;set;}
        @AuraEnabled public Decimal amount {get;set;}
        @AuraEnabled public String expiresAt {get;set;}
    }
}