public class MueveteSeguroService {
    
    private static final String NC = 'callout:MueveteSeguro_Bot_API';
    
    public static HttpResponse doGet(String path) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NC + path);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(60000);
        return new Http().send(req);
    }
    
    public static HttpResponse doPost(String path, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NC + path);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(body);
        req.setTimeout(60000);
        return new Http().send(req);
    }
    
    public static String getYears() {
        return doGet('/bot/catalog/years').getBody();
    }
    
    public static String getBrands(String yr) {
        return doGet('/bot/catalog/brands?year=' + EncodingUtil.urlEncode(yr, 'UTF-8')).getBody();
    }
    
    public static String getModels(String yr, String brandId) {
        return doGet('/bot/catalog/models?year=' + EncodingUtil.urlEncode(yr, 'UTF-8') + '&brandId=' + EncodingUtil.urlEncode(brandId, 'UTF-8')).getBody();
    }
    
    public static String getVersions(String yr, String modelId) {
        return doGet('/bot/catalog/versions?year=' + EncodingUtil.urlEncode(yr, 'UTF-8') + '&modelId=' + EncodingUtil.urlEncode(modelId, 'UTF-8')).getBody();
    }
    
    public static String createQuotation(String vehicleVersionId, String name, String phone, String email, String zipCode, String birthDate, String gender, String coverage) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('vehicleVersionId', vehicleVersionId);
        Map<String, Object> ins = new Map<String, Object>();
        ins.put('name', name);
        ins.put('phone', phone);
        if (String.isNotBlank(email)) ins.put('email', email);
        ins.put('zipCode', zipCode);
        ins.put('birthDate', birthDate);
        ins.put('gender', gender);
        payload.put('insured', ins);
        payload.put('coverage', coverage);
        return doPost('/bot/quotation', JSON.serialize(payload)).getBody();
    }
    
    public static String selectPlan(String quotationId, String insurer) {
        Map<String, Object> p = new Map<String, Object>();
        p.put('insurer', insurer);
        return doPost('/bot/quotation/' + quotationId + '/select', JSON.serialize(p)).getBody();
    }
    
    public static String submitInsuredData(String quotationId, String jsonData) {
        return doPost('/bot/quotation/' + quotationId + '/insured', jsonData).getBody();
    }
    
    public static String getPaymentLink(String policyId) {
        return doGet('/bot/policy/' + policyId + '/payment-link').getBody();
    }
    
    public static String getPolicyStatus(String policyId) {
        return doGet('/bot/policy/' + policyId).getBody();
    }
    
    public static String getInsurers() {
        return doGet('/bot/insurers').getBody();
    }
    
    public static String getCoverages() {
        return doGet('/bot/coverages').getBody();
    }
    
    public static String getQuotation(String quotationId) {
        return doGet('/bot/quotation/' + quotationId).getBody();
    }
}