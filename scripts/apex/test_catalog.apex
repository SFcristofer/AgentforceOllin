List<Tech_GetVehicleCatalog.CatalogRequest> reqs = new List<Tech_GetVehicleCatalog.CatalogRequest>();
Tech_GetVehicleCatalog.CatalogRequest r = new Tech_GetVehicleCatalog.CatalogRequest();
r.searchType = 'years';
reqs.add(r);
List<Tech_GetVehicleCatalog.CatalogResponse> res = Tech_GetVehicleCatalog.execute(reqs);
System.debug('TECH_DEBUG_RESULT: ' + JSON.serialize(res));