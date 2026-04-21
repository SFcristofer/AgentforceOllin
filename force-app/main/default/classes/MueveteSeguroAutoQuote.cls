public class MueveteSeguroAutoQuote {
    
    public class Input {
        @InvocableVariable(label='Marca del vehiculo' description='Marca del auto que el usuario quiere cotizar, por ejemplo: Volkswagen, Toyota, Nissan, Chevrolet, Honda, etc.' required=true)
        public String brand;
        
        @InvocableVariable(label='Modelo del vehiculo' description='Modelo o sub-marca del auto, por ejemplo: Jetta, Corolla, Versa, Aveo, Civic, etc.' required=false)
        public String model;
        
        @InvocableVariable(label='Anio del vehiculo' description='Anio de fabricacion del auto en formato de 4 digitos, por ejemplo: 2023, 2024, 2022.' required=true)
        public String year;
        
        @InvocableVariable(label='Nombre del conductor' description='Nombre completo o de pila del conductor que sera el asegurado.' required=true)
        public String fullName;
        
        @InvocableVariable(label='Telefono' description='Numero de telefono del cliente con codigo de pais, por ejemplo: +525512345678.' required=true)
        public String phone;
        
        @InvocableVariable(label='Codigo postal' description='Codigo postal de 5 digitos de la ubicacion del cliente en Mexico.' required=true)
        public String zipCode;
        
        @InvocableVariable(label='Fecha de nacimiento' description='Fecha de nacimiento del cliente en formato YYYY-MM-DD o DD/MM/YYYY.' required=true)
        public String birthDate;
        
        @InvocableVariable(label='Genero' description='Genero del cliente: M para masculino, F para femenino. Tambien acepta Masculino o Femenino.' required=true)
        public String gender;
        
        @InvocableVariable(label='Tipo de cobertura' description='Tipo de cobertura deseada: AMPLIA (completa), LIMITADA (basica) o RC (responsabilidad civil). Por defecto AMPLIA.' required=false)
        public String coverageType;
    }
    
    public class Output {
        @InvocableVariable(label='Resultado' description='Resultado con las cotizaciones de las aseguradoras o mensaje de error/siguiente paso.')
        public String result;
        
        @InvocableVariable(label='Exito' description='Indica si la operacion fue exitosa.')
        public Boolean success;
        
        @InvocableVariable(label='ID de Cotizacion' description='El quotationId para los siguientes pasos del flujo.')
        public String quotationId;
    }
    
    @InvocableMethod(label='Cotizar Seguro de Auto' description='ACCION PRINCIPAL PARA SEGURO DE AUTO. Recibe marca, modelo, anio del vehiculo junto con datos del conductor (nombre, telefono, CP, fecha nacimiento, genero) y automaticamente busca el vehiculo en el catalogo y genera cotizacion con las 5 aseguradoras (HDI, ANA, GNP, QUALITAS, CHUBB). Usa esta accion SIEMPRE que el usuario quiera cotizar seguro de auto, carro, coche o vehiculo.')
    public static List<Output> quoteAuto(List<Input> inputs) {
        Input inp = inputs[0];
        Output out = new Output();
        out.success = false;
        
        try {
            String genderNorm = normalizeGender(inp.gender);
            String birthDateNorm = normalizeBirthDate(inp.birthDate);
            String coverage = String.isNotBlank(inp.coverageType) ? inp.coverageType.toUpperCase() : 'AMPLIA';
            String yearStr = inp.year.trim();
            
            // Step 1: Get brands for year
            HttpResponse brandsResp = MueveteSeguroService.doGet('/bot/catalog/brands?year=' + yearStr);
            if (brandsResp.getStatusCode() != 200) {
                out.result = 'Error al buscar marcas para ' + yearStr + '. Codigo: ' + brandsResp.getStatusCode();
                return new List<Output>{ out };
            }
            
            List<Object> brands = (List<Object>) JSON.deserializeUntyped(brandsResp.getBody());
            String brandId = null;
            String brandName = null;
            String brandSearch = inp.brand.trim().toLowerCase();
            
            for (Object b : brands) {
                Map<String, Object> bm = (Map<String, Object>) b;
                String bName = ((String) bm.get('name')).toLowerCase();
                if (bName.contains(brandSearch) || brandSearch.contains(bName)) {
                    brandId = String.valueOf(bm.get('id'));
                    brandName = (String) bm.get('name');
                    break;
                }
            }
            
            if (brandId == null) {
                List<String> names = new List<String>();
                for (Object b : brands) {
                    names.add((String) ((Map<String, Object>) b).get('name'));
                }
                out.result = 'No encontre la marca "' + inp.brand + '" para ' + yearStr + '. Marcas disponibles: ' + String.join(names, ', ') + '. Pregunta al usuario cual desea.';
                return new List<Output>{ out };
            }
            
            // Step 2: Get models
            HttpResponse modelsResp = MueveteSeguroService.doGet('/bot/catalog/models?year=' + yearStr + '&brandId=' + brandId);
            if (modelsResp.getStatusCode() != 200) {
                out.result = 'Error al buscar modelos de ' + brandName + ' ' + yearStr;
                return new List<Output>{ out };
            }
            
            List<Object> models = (List<Object>) JSON.deserializeUntyped(modelsResp.getBody());
            String modelId = null;
            String modelName = null;
            
            if (String.isNotBlank(inp.model)) {
                String modelSearch = inp.model.trim().toLowerCase();
                for (Object m : models) {
                    Map<String, Object> mm = (Map<String, Object>) m;
                    String mName = ((String) mm.get('name')).toLowerCase();
                    if (mName.contains(modelSearch) || modelSearch.contains(mName)) {
                        modelId = String.valueOf(mm.get('id'));
                        modelName = (String) mm.get('name');
                        break;
                    }
                }
            }
            
            if (modelId == null) {
                List<String> names = new List<String>();
                for (Object m : models) {
                    names.add((String) ((Map<String, Object>) m).get('name'));
                }
                String msg = String.isNotBlank(inp.model) ? 'No encontre "' + inp.model + '" de ' + brandName + ' ' + yearStr + '.' : 'Modelos de ' + brandName + ' ' + yearStr + ':';
                out.result = msg + ' Disponibles: ' + String.join(names, ', ') + '. Pregunta al usuario cual modelo desea.';
                return new List<Output>{ out };
            }
            
            // Step 3: Get versions
            HttpResponse versResp = MueveteSeguroService.doGet('/bot/catalog/versions?year=' + yearStr + '&modelId=' + modelId);
            if (versResp.getStatusCode() != 200) {
                out.result = 'Error al buscar versiones de ' + brandName + ' ' + modelName + ' ' + yearStr;
                return new List<Output>{ out };
            }
            
            List<Object> versions = (List<Object>) JSON.deserializeUntyped(versResp.getBody());
            
            if (versions.isEmpty()) {
                out.result = 'No hay versiones para ' + brandName + ' ' + modelName + ' ' + yearStr;
                return new List<Output>{ out };
            }
            
            if (versions.size() > 1) {
                List<String> vList = new List<String>();
                Integer idx = 1;
                for (Object v : versions) {
                    Map<String, Object> vm = (Map<String, Object>) v;
                    vList.add(idx + '. ' + (String) vm.get('name') + ' (ID: ' + String.valueOf(vm.get('id')) + ')');
                    idx++;
                }
                out.result = 'Encontre ' + versions.size() + ' versiones de ' + brandName + ' ' + modelName + ' ' + yearStr + ': ' + String.join(vList, ' | ') + '. Pregunta al usuario cual version desea. Una vez que elija, usa la accion Generar Cotizacion de Seguro con el vehicleVersionId seleccionado.';
                out.success = true;
                return new List<Output>{ out };
            }
            
            // Single version - auto-quote
            Map<String, Object> ver = (Map<String, Object>) versions[0];
            String verId = String.valueOf(ver.get('id'));
            
            // Step 4: Generate quotation
            Map<String, Object> body = new Map<String, Object>();
            body.put('vehicleVersionId', Integer.valueOf(verId));
            Map<String, Object> ins = new Map<String, Object>();
            ins.put('name', inp.fullName);
            ins.put('phone', inp.phone);
            ins.put('zipCode', inp.zipCode);
            ins.put('birthDate', birthDateNorm);
            ins.put('gender', genderNorm);
            body.put('insured', ins);
            body.put('coverage', coverage);
            
            HttpResponse qResp = MueveteSeguroService.doPost('/bot/quotation', JSON.serialize(body));
            
            if (qResp.getStatusCode() != 200 && qResp.getStatusCode() != 201) {
                out.result = 'Error al cotizar ' + brandName + ' ' + modelName + ' ' + yearStr + ': ' + qResp.getBody();
                return new List<Output>{ out };
            }
            
            Map<String, Object> qr = (Map<String, Object>) JSON.deserializeUntyped(qResp.getBody());
            out.quotationId = (String) qr.get('quotationId');
            out.success = true;
            out.result = qResp.getBody();
            return new List<Output>{ out };
            
        } catch (Exception e) {
            out.result = 'Error: ' + e.getMessage() + ' linea ' + e.getLineNumber();
            return new List<Output>{ out };
        }
    }
    
    private static String normalizeGender(String gender) {
        if (String.isBlank(gender)) return 'M';
        String g = gender.trim().toLowerCase();
        if (g.startsWith('f') || g.contains('mujer') || g.contains('femen')) return 'F';
        return 'M';
    }
    
    private static String normalizeBirthDate(String bd) {
        if (String.isBlank(bd)) return bd;
        String d = bd.trim();
        if (d.contains('/')) {
            List<String> p = d.split('/');
            if (p.size() == 3) {
                if (p[0].length() == 4) return d.replace('/', '-');
                return p[2] + '-' + p[1] + '-' + p[0];
            }
        }
        return d;
    }
}