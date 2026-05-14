@isTest
public class Tech_IdentitySearchTest {
    
    @testSetup
    static void setup() {
        // Crear un Contacto de prueba
        insert new Contact(
            FirstName = 'Juan',
            LastName = 'Perez',
            Email = 'juan.perez@test.com'
        );
        
        // Crear un Lead de prueba
        insert new Lead(
            FirstName = 'Maria',
            LastName = 'Gomez',
            Email = 'maria.gomez@test.com',
            Company = 'Test Co'
        );
    }

    @isTest
    static void testSearchContact() {
        Tech_IdentitySearch.IdentityRequest req = new Tech_IdentitySearch.IdentityRequest();
        req.email = 'juan.perez@test.com';
        
        Test.startTest();
        List<Tech_IdentitySearch.IdentityResult> results = Tech_IdentitySearch.searchIdentity(new List<Tech_IdentitySearch.IdentityRequest>{req});
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isExisting);
        System.assertEquals('Juan Perez', results[0].foundName);
        System.assertEquals('Cliente', results[0].clientType);
    }

    @isTest
    static void testSearchLead() {
        Tech_IdentitySearch.IdentityRequest req = new Tech_IdentitySearch.IdentityRequest();
        req.email = 'maria.gomez@test.com';
        
        Test.startTest();
        List<Tech_IdentitySearch.IdentityResult> results = Tech_IdentitySearch.searchIdentity(new List<Tech_IdentitySearch.IdentityRequest>{req});
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        System.assertEquals(true, results[0].isExisting);
        System.assertEquals('Maria Gomez', results[0].foundName);
        System.assertEquals('Prospecto', results[0].clientType);
    }

    @isTest
    static void testNotFound() {
        Tech_IdentitySearch.IdentityRequest req = new Tech_IdentitySearch.IdentityRequest();
        req.email = 'no.existe@test.com';
        
        Test.startTest();
        List<Tech_IdentitySearch.IdentityResult> results = Tech_IdentitySearch.searchIdentity(new List<Tech_IdentitySearch.IdentityRequest>{req});
        Test.stopTest();
        
        System.assertEquals(1, results.size());
        System.assertEquals(false, results[0].isExisting);
        System.assert(String.isBlank(results[0].foundName));
    }
}
