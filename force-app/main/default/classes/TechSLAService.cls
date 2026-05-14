public without sharing class TechSLAService {

    /*
     * =====================================================================================
     * CLASE: TechSLAService
     * =====================================================================================
     *
     * Objetivo:
     * - Calcular SLA para Lead y Opportunity.
     * - Asignar responsable según cadencia, ramo y producto.
     * - Crear tareas de seguimiento.
     * - Enviar notificaciones por email.
     * - Evaluar vencimientos y escalamientos.
     *
     * SLA:
     * A = Atención inmediata.
     * B = Seguimiento corto.
     * C = Análisis comercial.
     * D = Pago pendiente / crítico.
     */

    public static final String FIELD_SLA_CADENCIA = 'Tech_SLA_Cadencia__c';
    public static final String FIELD_SLA_INICIO = 'Tech_SLA_Fecha_Inicio__c';
    public static final String FIELD_SLA_LIMITE = 'Tech_SLA_Fecha_Limite__c';
    public static final String FIELD_SLA_ESTATUS = 'Tech_SLA_Estatus__c';
    public static final String FIELD_SLA_NIVEL = 'Tech_SLA_Nivel_Escalacion__c';
    public static final String FIELD_SLA_PAUSADO = 'Tech_SLA_Pausado__c';
    public static final String FIELD_SLA_MOTIVO_PAUSA = 'Tech_SLA_Motivo_Pausa__c';
    public static final String FIELD_SLA_ULTIMA_ACTIVIDAD = 'Tech_SLA_Ultima_Actividad__c';

    public static final String SLA_EN_TIEMPO = 'En tiempo';
    public static final String SLA_VENCIDO = 'Vencido';
    public static final String SLA_ESCALADO = 'Escalado';
    public static final String SLA_PAUSADO = 'Pausado';
    public static final String SLA_CUMPLIDO = 'Cumplido';

    public static final String CADENCIA_A = 'A - Atención inmediata';
    public static final String CADENCIA_B = 'B - Seguimiento corto';
    public static final String CADENCIA_C = 'C - Análisis comercial';
    public static final String CADENCIA_D = 'D - Pago pendiente / crítico';

    private static final Integer MINUTOS_CADENCIA_A = 15;
    private static final Integer MINUTOS_CADENCIA_B = 30;
    private static final Integer MINUTOS_CADENCIA_C = 60;
    private static final Integer MINUTOS_CADENCIA_D = 1440;

    private static final String OBJETO_REGLA_ASIGNACION = 'Tech_Regla_Asignacion_SLA__c';

    private class AvisoSLA {
        Id ownerId;
        Id registroId;
        String objeto;
        String nombreRegistro;
        String asunto;
        String mensaje;
        Boolean esEscalamiento;
    }

    /*
     * =====================================================================================
     * BEFORE LEAD
     * =====================================================================================
     */
    public static void beforeSaveLead(
        List<Lead> nuevos,
        Map<Id, Lead> anteriores
    ) {

        if (nuevos == null || nuevos.isEmpty()) {
            return;
        }

        for (Lead lead : nuevos) {

            if (lead == null) {
                continue;
            }

            if (lead.IsConverted == true) {
                marcarSLACumplido(lead);
                continue;
            }

            if (getBoolean(lead, FIELD_SLA_PAUSADO) == true) {
                putIfExists(lead, FIELD_SLA_ESTATUS, SLA_PAUSADO);
                continue;
            }

            if (!debeRecalcularSLA(lead, anteriores)) {
                continue;
            }

            aplicarSLA(lead, 'Lead');

            Id ownerAsignado = resolverOwnerSLA(
                'Lead',
                getString(lead, FIELD_SLA_CADENCIA),
                obtenerRamo(lead),
                obtenerProducto(lead),
                lead.OwnerId
            );

            if (ownerAsignado != null) {
                lead.OwnerId = ownerAsignado;
            }
        }
    }

    /*
     * =====================================================================================
     * BEFORE OPPORTUNITY
     * =====================================================================================
     */
    public static void beforeSaveOpportunity(
        List<Opportunity> nuevas,
        Map<Id, Opportunity> anteriores
    ) {

        if (nuevas == null || nuevas.isEmpty()) {
            return;
        }

        for (Opportunity opp : nuevas) {

            if (opp == null) {
                continue;
            }

            if (opp.IsClosed == true) {
                marcarSLACumplido(opp);
                continue;
            }

            if (getBoolean(opp, FIELD_SLA_PAUSADO) == true) {
                putIfExists(opp, FIELD_SLA_ESTATUS, SLA_PAUSADO);
                continue;
            }

            if (!debeRecalcularSLA(opp, anteriores)) {
                continue;
            }

            aplicarSLA(opp, 'Opportunity');

            Id ownerAsignado = resolverOwnerSLA(
                'Opportunity',
                getString(opp, FIELD_SLA_CADENCIA),
                obtenerRamo(opp),
                obtenerProducto(opp),
                opp.OwnerId
            );

            /*
             * Opportunity normalmente debe tener propietario tipo User.
             */
            if (
                ownerAsignado != null &&
                String.valueOf(ownerAsignado).startsWith('005')
            ) {
                opp.OwnerId = ownerAsignado;
            }
        }
    }

    /*
     * =====================================================================================
     * AFTER LEAD
     * =====================================================================================
     */
    public static void afterSaveLead(
        List<Lead> nuevos,
        Map<Id, Lead> anteriores,
        Boolean esInsert
    ) {

        if (nuevos == null || nuevos.isEmpty()) {
            return;
        }

        List<Task> tareas = new List<Task>();
        List<AvisoSLA> avisos = new List<AvisoSLA>();

        for (Lead lead : nuevos) {

            if (lead == null || lead.IsConverted == true) {
                continue;
            }

            if (!debeCrearSeguimientoSLA(lead, anteriores, esInsert)) {
                continue;
            }

            Task tarea = construirTareaLead(lead, false);

            if (tarea != null) {
                tareas.add(tarea);
            }

            AvisoSLA aviso = construirAvisoLead(lead, false);

            if (aviso != null) {
                avisos.add(aviso);
            }
        }

        if (!tareas.isEmpty()) {
            insert tareas;
        }

        enviarNotificaciones(avisos);
    }

    /*
     * =====================================================================================
     * AFTER OPPORTUNITY
     * =====================================================================================
     */
    public static void afterSaveOpportunity(
        List<Opportunity> nuevas,
        Map<Id, Opportunity> anteriores,
        Boolean esInsert
    ) {

        if (nuevas == null || nuevas.isEmpty()) {
            return;
        }

        List<Task> tareas = new List<Task>();
        List<AvisoSLA> avisos = new List<AvisoSLA>();

        for (Opportunity opp : nuevas) {

            if (opp == null || opp.IsClosed == true) {
                continue;
            }

            if (!debeCrearSeguimientoSLA(opp, anteriores, esInsert)) {
                continue;
            }

            Task tarea = construirTareaOpportunity(opp, false);

            if (tarea != null) {
                tareas.add(tarea);
            }

            AvisoSLA aviso = construirAvisoOpportunity(opp, false);

            if (aviso != null) {
                avisos.add(aviso);
            }
        }

        if (!tareas.isEmpty()) {
            insert tareas;
        }

        enviarNotificaciones(avisos);
    }

    /*
     * =====================================================================================
     * APLICAR SLA
     * =====================================================================================
     */
    private static void aplicarSLA(
        SObject registro,
        String nombreObjeto
    ) {

        String cadencia = determinarCadencia(registro);
        Integer minutos = obtenerMinutosPorCadencia(cadencia);

        Datetime ahora = Datetime.now();
        Datetime fechaLimite = ahora.addMinutes(minutos);

        putIfExists(registro, FIELD_SLA_CADENCIA, cadencia);
        putIfExists(registro, FIELD_SLA_INICIO, ahora);
        putIfExists(registro, FIELD_SLA_LIMITE, fechaLimite);
        putIfExists(registro, FIELD_SLA_ESTATUS, SLA_EN_TIEMPO);
        putIfExists(registro, FIELD_SLA_ULTIMA_ACTIVIDAD, ahora);

        if (getDecimal(registro, FIELD_SLA_NIVEL) == null) {
            putIfExists(registro, FIELD_SLA_NIVEL, 0);
        }
    }

    private static void marcarSLACumplido(SObject registro) {
        putIfExists(registro, FIELD_SLA_ESTATUS, SLA_CUMPLIDO);
        putIfExists(registro, FIELD_SLA_ULTIMA_ACTIVIDAD, Datetime.now());
    }

    /*
     * =====================================================================================
     * DETERMINAR CADENCIA
     * =====================================================================================
     */
    private static String determinarCadencia(SObject registro) {

        String texto = normalizar(
            getString(registro, 'Status') + ' ' +
            getString(registro, 'StageName') + ' ' +
            getString(registro, 'Ramo__c') + ' ' +
            getString(registro, 'Tech_Ramo__c') + ' ' +
            getString(registro, 'Producto_Interes__c') + ' ' +
            getString(registro, 'Tech_Producto_Interes__c') + ' ' +
            getString(registro, 'Tipo_Operacion__c')
        );

        if (
            texto.contains('PAGO') ||
            texto.contains('PENDIENTE DE PAGO')
        ) {
            return CADENCIA_D;
        }

        if (
            texto.contains('INCOMPLET') ||
            texto.contains('ABANDON') ||
            texto.contains('SIN INFORMACION') ||
            texto.contains('SIN INFORMACIÓN')
        ) {
            return CADENCIA_A;
        }

        if (
            texto.contains('COTIZ') ||
            texto.contains('PROPUESTA')
        ) {
            return CADENCIA_B;
        }

        if (
            texto.contains('VIDA') ||
            texto.contains('GMM') ||
            texto.contains('GASTOS') ||
            texto.contains('PPR') ||
            texto.contains('INVERSION') ||
            texto.contains('INVERSIÓN')
        ) {
            return CADENCIA_C;
        }

        if (
            texto.contains('AUTO') ||
            texto.contains('AUTOS')
        ) {
            return CADENCIA_A;
        }

        return CADENCIA_B;
    }

    private static Integer obtenerMinutosPorCadencia(String cadencia) {

        if (cadencia == CADENCIA_A) {
            return MINUTOS_CADENCIA_A;
        }

        if (cadencia == CADENCIA_B) {
            return MINUTOS_CADENCIA_B;
        }

        if (cadencia == CADENCIA_C) {
            return MINUTOS_CADENCIA_C;
        }

        if (cadencia == CADENCIA_D) {
            return MINUTOS_CADENCIA_D;
        }

        return MINUTOS_CADENCIA_B;
    }

    /*
     * =====================================================================================
     * ASIGNACIÓN SLA
     * =====================================================================================
     */
    private static Id resolverOwnerSLA(
        String objeto,
        String cadencia,
        String ramo,
        String producto,
        Id ownerActual
    ) {

        Id ownerPorRegla = obtenerOwnerDesdeRegla(
            objeto,
            cadencia,
            ramo,
            producto
        );

        if (ownerPorRegla != null) {

            if (objeto == 'Opportunity') {
                if (String.valueOf(ownerPorRegla).startsWith('005')) {
                    return ownerPorRegla;
                }

                return ownerActual != null
                    ? ownerActual
                    : UserInfo.getUserId();
            }

            return ownerPorRegla;
        }

        if (ownerActual != null) {
            return ownerActual;
        }

        return UserInfo.getUserId();
    }

    private static Id obtenerOwnerDesdeRegla(
        String objeto,
        String cadencia,
        String ramo,
        String producto
    ) {

        Map<String, Schema.SObjectType> globalDescribe =
            Schema.getGlobalDescribe();

        if (!globalDescribe.containsKey(OBJETO_REGLA_ASIGNACION)) {
            return null;
        }

        Schema.SObjectType tipoRegla =
            globalDescribe.get(OBJETO_REGLA_ASIGNACION);

        Schema.DescribeSObjectResult describe =
            tipoRegla.getDescribe();

        List<String> campos = new List<String>{ 'Id' };

        agregarCampoSiExiste(describe, campos, 'Activo__c');
        agregarCampoSiExiste(describe, campos, 'Objeto__c');
        agregarCampoSiExiste(describe, campos, 'Ramo__c');
        agregarCampoSiExiste(describe, campos, 'Producto__c');
        agregarCampoSiExiste(describe, campos, 'Cadencia__c');
        agregarCampoSiExiste(describe, campos, 'Usuario__c');
        agregarCampoSiExiste(describe, campos, 'User__c');
        agregarCampoSiExiste(describe, campos, 'OwnerId__c');
        agregarCampoSiExiste(describe, campos, 'Cola__c');
        agregarCampoSiExiste(describe, campos, 'Queue__c');
        agregarCampoSiExiste(describe, campos, 'Prioridad__c');

        String soql =
            'SELECT ' + String.join(campos, ',') +
            ' FROM ' + OBJETO_REGLA_ASIGNACION;

        if (describe.fields.getMap().containsKey('Activo__c')) {
            soql += ' WHERE Activo__c = true';
        }

        if (describe.fields.getMap().containsKey('Prioridad__c')) {
            soql += ' ORDER BY Prioridad__c ASC';
        }

        for (SObject regla : Database.query(soql)) {

            if (!coincideRegla(regla, 'Objeto__c', objeto)) {
                continue;
            }

            if (!coincideReglaFlexible(regla, 'Ramo__c', ramo)) {
                continue;
            }

            if (!coincideReglaFlexible(regla, 'Producto__c', producto)) {
                continue;
            }

            if (!coincideReglaFlexible(regla, 'Cadencia__c', cadencia)) {
                continue;
            }

            Id ownerId = obtenerOwnerDeRegla(regla);

            if (ownerId != null) {
                return ownerId;
            }
        }

        return null;
    }

    private static Boolean coincideRegla(
        SObject regla,
        String campo,
        String valorEsperado
    ) {

        String valorRegla = normalizar(getString(regla, campo));
        String valor = normalizar(valorEsperado);

        if (String.isBlank(valorRegla)) {
            return true;
        }

        return valorRegla == valor;
    }

    private static Boolean coincideReglaFlexible(
        SObject regla,
        String campo,
        String valorEsperado
    ) {

        String valorRegla = normalizar(getString(regla, campo));
        String valor = normalizar(valorEsperado);

        if (String.isBlank(valorRegla)) {
            return true;
        }

        if (String.isBlank(valor)) {
            return false;
        }

        return valor.contains(valorRegla) || valorRegla.contains(valor);
    }

    private static Id obtenerOwnerDeRegla(SObject regla) {

        Id usuario = getId(regla, 'Usuario__c');

        if (usuario != null) {
            return usuario;
        }

        usuario = getId(regla, 'User__c');

        if (usuario != null) {
            return usuario;
        }

        Id cola = getId(regla, 'Cola__c');

        if (cola != null) {
            return cola;
        }

        cola = getId(regla, 'Queue__c');

        if (cola != null) {
            return cola;
        }

        String ownerTexto = getString(regla, 'OwnerId__c');

        if (!String.isBlank(ownerTexto)) {
            try {
                return (Id) ownerTexto;
            } catch (Exception e) {
                return null;
            }
        }

        return null;
    }

    /*
     * =====================================================================================
     * CREACIÓN DE TAREAS
     * =====================================================================================
     */
    private static Task construirTareaLead(
        Lead lead,
        Boolean esEscalamiento
    ) {

        if (lead == null || lead.Id == null) {
            return null;
        }

        Task tarea = new Task();

        tarea.WhoId = lead.Id;
        tarea.OwnerId = obtenerOwnerTarea(lead.OwnerId);
        tarea.Subject = esEscalamiento
            ? 'SLA vencido - contactar prospecto'
            : 'Seguimiento SLA - contactar prospecto';
        tarea.Status = 'Not Started';
        tarea.Priority = esEscalamiento ? 'High' : 'Normal';
        tarea.ActivityDate = Date.today();

        tarea.Description =
            'Seguimiento automático por SLA. ' +
            'Cadencia: ' + getString(lead, FIELD_SLA_CADENCIA) + '. ' +
            'Fecha límite: ' + String.valueOf(getDatetime(lead, FIELD_SLA_LIMITE)) + '.';

        return tarea;
    }

    private static Task construirTareaOpportunity(
        Opportunity opp,
        Boolean esEscalamiento
    ) {

        if (opp == null || opp.Id == null) {
            return null;
        }

        Task tarea = new Task();

        tarea.WhatId = opp.Id;
        tarea.OwnerId = obtenerOwnerTarea(opp.OwnerId);
        tarea.Subject = esEscalamiento
            ? 'SLA vencido - seguimiento oportunidad'
            : 'Seguimiento SLA - oportunidad';
        tarea.Status = 'Not Started';
        tarea.Priority = esEscalamiento ? 'High' : 'Normal';
        tarea.ActivityDate = Date.today();

        tarea.Description =
            'Seguimiento automático por SLA. ' +
            'Cadencia: ' + getString(opp, FIELD_SLA_CADENCIA) + '. ' +
            'Fecha límite: ' + String.valueOf(getDatetime(opp, FIELD_SLA_LIMITE)) + '.';

        return tarea;
    }

    private static Id obtenerOwnerTarea(Id ownerId) {

        if (ownerId != null && String.valueOf(ownerId).startsWith('005')) {
            return ownerId;
        }

        return UserInfo.getUserId();
    }

    /*
     * =====================================================================================
     * NOTIFICACIONES
     * =====================================================================================
     */
    private static AvisoSLA construirAvisoLead(
        Lead lead,
        Boolean esEscalamiento
    ) {

        if (lead == null || lead.Id == null) {
            return null;
        }

        AvisoSLA aviso = new AvisoSLA();

        aviso.ownerId = lead.OwnerId;
        aviso.registroId = lead.Id;
        aviso.objeto = 'Lead';
        aviso.nombreRegistro = lead.Name;
        aviso.esEscalamiento = esEscalamiento;
        aviso.asunto = esEscalamiento
            ? 'SLA vencido - Prospecto requiere atención'
            : 'Nuevo seguimiento SLA asignado - Prospecto';
        aviso.mensaje =
            'Se requiere seguimiento del prospecto: ' + lead.Name + '\n' +
            'Cadencia: ' + getString(lead, FIELD_SLA_CADENCIA) + '\n' +
            'Fecha límite: ' + String.valueOf(getDatetime(lead, FIELD_SLA_LIMITE)) + '\n' +
            'Estatus SLA: ' + getString(lead, FIELD_SLA_ESTATUS);

        return aviso;
    }

    private static AvisoSLA construirAvisoOpportunity(
        Opportunity opp,
        Boolean esEscalamiento
    ) {

        if (opp == null || opp.Id == null) {
            return null;
        }

        AvisoSLA aviso = new AvisoSLA();

        aviso.ownerId = opp.OwnerId;
        aviso.registroId = opp.Id;
        aviso.objeto = 'Opportunity';
        aviso.nombreRegistro = opp.Name;
        aviso.esEscalamiento = esEscalamiento;
        aviso.asunto = esEscalamiento
            ? 'SLA vencido - Oportunidad requiere atención'
            : 'Nuevo seguimiento SLA asignado - Oportunidad';
        aviso.mensaje =
            'Se requiere seguimiento de la oportunidad: ' + opp.Name + '\n' +
            'Cadencia: ' + getString(opp, FIELD_SLA_CADENCIA) + '\n' +
            'Fecha límite: ' + String.valueOf(getDatetime(opp, FIELD_SLA_LIMITE)) + '\n' +
            'Estatus SLA: ' + getString(opp, FIELD_SLA_ESTATUS);

        return aviso;
    }

    private static void enviarNotificaciones(List<AvisoSLA> avisos) {

        if (avisos == null || avisos.isEmpty()) {
            return;
        }

        Set<Id> userIds = new Set<Id>();
        Set<Id> groupIds = new Set<Id>();

        for (AvisoSLA aviso : avisos) {

            if (aviso == null || aviso.ownerId == null) {
                continue;
            }

            String ownerTexto = String.valueOf(aviso.ownerId);

            if (ownerTexto.startsWith('005')) {
                userIds.add(aviso.ownerId);
            }

            if (ownerTexto.startsWith('00G')) {
                groupIds.add(aviso.ownerId);
            }
        }

        Map<Id, Set<Id>> usuariosPorGrupo = new Map<Id, Set<Id>>();

        if (!groupIds.isEmpty()) {
            for (GroupMember gm : [
                SELECT GroupId,
                       UserOrGroupId
                FROM GroupMember
                WHERE GroupId IN :groupIds
            ]) {

                if (!usuariosPorGrupo.containsKey(gm.GroupId)) {
                    usuariosPorGrupo.put(gm.GroupId, new Set<Id>());
                }

                if (String.valueOf(gm.UserOrGroupId).startsWith('005')) {
                    usuariosPorGrupo.get(gm.GroupId).add(gm.UserOrGroupId);
                    userIds.add(gm.UserOrGroupId);
                }
            }
        }

        Map<Id, User> usuarios = new Map<Id, User>();

        if (!userIds.isEmpty()) {
            usuarios = new Map<Id, User>([
                SELECT Id,
                       Name,
                       Email,
                       IsActive
                FROM User
                WHERE Id IN :userIds
                  AND IsActive = true
                  AND Email != null
            ]);
        }

        List<Messaging.SingleEmailMessage> correos =
            new List<Messaging.SingleEmailMessage>();

        for (AvisoSLA aviso : avisos) {

            Set<String> destinatarios = new Set<String>();

            if (aviso.ownerId == null) {
                continue;
            }

            String ownerTexto = String.valueOf(aviso.ownerId);

            if (
                ownerTexto.startsWith('005') &&
                usuarios.containsKey(aviso.ownerId)
            ) {
                destinatarios.add(usuarios.get(aviso.ownerId).Email);
            }

            if (
                ownerTexto.startsWith('00G') &&
                usuariosPorGrupo.containsKey(aviso.ownerId)
            ) {
                for (Id userId : usuariosPorGrupo.get(aviso.ownerId)) {
                    if (usuarios.containsKey(userId)) {
                        destinatarios.add(usuarios.get(userId).Email);
                    }
                }
            }

            if (destinatarios.isEmpty()) {
                continue;
            }

            Messaging.SingleEmailMessage correo =
                new Messaging.SingleEmailMessage();

            correo.setToAddresses(new List<String>(destinatarios));
            correo.setSubject(aviso.asunto);
            correo.setPlainTextBody(aviso.mensaje);
            correo.setSaveAsActivity(false);

            correos.add(correo);
        }

        if (!correos.isEmpty()) {
            try {
                Messaging.sendEmail(correos, false);
            } catch (Exception e) {
                System.debug('Error enviando notificaciones SLA: ' + e.getMessage());
            }
        }
    }

    /*
     * =====================================================================================
     * EVALUAR VENCIDOS LEAD
     * =====================================================================================
     */
    public static void evaluarLeadsVencidos(List<Lead> leads) {

        if (leads == null || leads.isEmpty()) {
            return;
        }

        List<Lead> leadsActualizar = new List<Lead>();
        List<Task> tareas = new List<Task>();
        List<AvisoSLA> avisos = new List<AvisoSLA>();

        Datetime ahora = Datetime.now();

        for (Lead lead : leads) {

            if (lead == null || lead.IsConverted == true) {
                continue;
            }

            if (getBoolean(lead, FIELD_SLA_PAUSADO) == true) {
                continue;
            }

            Datetime limite = getDatetime(lead, FIELD_SLA_LIMITE);

            if (limite == null || limite > ahora) {
                continue;
            }

            Decimal nivel = getDecimal(lead, FIELD_SLA_NIVEL);

            if (nivel == null) {
                nivel = 0;
            }

            Lead actualizar = new Lead(Id = lead.Id);

            String nuevoEstatus = nivel >= 1 ? SLA_ESCALADO : SLA_VENCIDO;

            putIfExists(actualizar, FIELD_SLA_ESTATUS, nuevoEstatus);
            putIfExists(actualizar, FIELD_SLA_NIVEL, nivel + 1);
            putIfExists(actualizar, FIELD_SLA_ULTIMA_ACTIVIDAD, ahora);

            leadsActualizar.add(actualizar);

            Task tarea = construirTareaLead(lead, true);

            if (tarea != null) {
                tareas.add(tarea);
            }

            AvisoSLA aviso = construirAvisoLead(lead, true);

            if (aviso != null) {
                avisos.add(aviso);
            }
        }

        if (!leadsActualizar.isEmpty()) {
            update leadsActualizar;
        }

        if (!tareas.isEmpty()) {
            insert tareas;
        }

        enviarNotificaciones(avisos);
    }

    /*
     * =====================================================================================
     * EVALUAR VENCIDOS OPPORTUNITY
     * =====================================================================================
     */
    public static void evaluarOportunidadesVencidas(
        List<Opportunity> oportunidades
    ) {

        if (oportunidades == null || oportunidades.isEmpty()) {
            return;
        }

        List<Opportunity> oportunidadesActualizar = new List<Opportunity>();
        List<Task> tareas = new List<Task>();
        List<AvisoSLA> avisos = new List<AvisoSLA>();

        Datetime ahora = Datetime.now();

        for (Opportunity opp : oportunidades) {

            if (opp == null || opp.IsClosed == true) {
                continue;
            }

            if (getBoolean(opp, FIELD_SLA_PAUSADO) == true) {
                continue;
            }

            Datetime limite = getDatetime(opp, FIELD_SLA_LIMITE);

            if (limite == null || limite > ahora) {
                continue;
            }

            Decimal nivel = getDecimal(opp, FIELD_SLA_NIVEL);

            if (nivel == null) {
                nivel = 0;
            }

            Opportunity actualizar = new Opportunity(Id = opp.Id);

            String nuevoEstatus = nivel >= 1 ? SLA_ESCALADO : SLA_VENCIDO;

            putIfExists(actualizar, FIELD_SLA_ESTATUS, nuevoEstatus);
            putIfExists(actualizar, FIELD_SLA_NIVEL, nivel + 1);
            putIfExists(actualizar, FIELD_SLA_ULTIMA_ACTIVIDAD, ahora);

            oportunidadesActualizar.add(actualizar);

            Task tarea = construirTareaOpportunity(opp, true);

            if (tarea != null) {
                tareas.add(tarea);
            }

            AvisoSLA aviso = construirAvisoOpportunity(opp, true);

            if (aviso != null) {
                avisos.add(aviso);
            }
        }

        if (!oportunidadesActualizar.isEmpty()) {
            update oportunidadesActualizar;
        }

        if (!tareas.isEmpty()) {
            insert tareas;
        }

        enviarNotificaciones(avisos);
    }

    /*
     * =====================================================================================
     * REGLAS DE RECÁLCULO Y SEGUIMIENTO
     * =====================================================================================
     */


    private static Boolean debeRecalcularSLA(
        Lead nuevo,
        Map<Id, Lead> anteriores
    ) {
    
        if (nuevo == null) {
            return false;
        }
    
        if (anteriores == null || nuevo.Id == null) {
            return true;
        }
    
        Lead anterior = anteriores.get(nuevo.Id);
    
        if (anterior == null) {
            return true;
        }
    
        return debeRecalcularSLAComun(nuevo, anterior);
    }
    
    /*
     * -----------------------------------------------------------------------------
     * RECÁLCULO SLA - OPPORTUNITY
     * -----------------------------------------------------------------------------
     */
    private static Boolean debeRecalcularSLA(
        Opportunity nuevo,
        Map<Id, Opportunity> anteriores
    ) {
    
        if (nuevo == null) {
            return false;
        }
    
        if (anteriores == null || nuevo.Id == null) {
            return true;
        }
    
        Opportunity anterior = anteriores.get(nuevo.Id);
    
        if (anterior == null) {
            return true;
        }
    
        return debeRecalcularSLAComun(nuevo, anterior);
    }
    
    /*
     * -----------------------------------------------------------------------------
     * LÓGICA COMÚN DE RECÁLCULO
     * -----------------------------------------------------------------------------
     */
    private static Boolean debeRecalcularSLAComun(
        SObject nuevo,
        SObject anterior
    ) {
    
        if (nuevo == null) {
            return false;
        }
    
        if (anterior == null) {
            return true;
        }
    
        return
            getString(nuevo, 'Status') != getString(anterior, 'Status') ||
            getString(nuevo, 'StageName') != getString(anterior, 'StageName') ||
            obtenerRamo(nuevo) != obtenerRamo(anterior) ||
            obtenerProducto(nuevo) != obtenerProducto(anterior) ||
            getString(nuevo, 'Tipo_Operacion__c') != getString(anterior, 'Tipo_Operacion__c') ||
            getString(nuevo, FIELD_SLA_ESTATUS) == null;
    }
    
    /*
     * -----------------------------------------------------------------------------
     * CREACIÓN DE SEGUIMIENTO SLA - LEAD
     * -----------------------------------------------------------------------------
     */
    private static Boolean debeCrearSeguimientoSLA(
        Lead nuevo,
        Map<Id, Lead> anteriores,
        Boolean esInsert
    ) {
    
        if (nuevo == null) {
            return false;
        }
    
        if (getBoolean(nuevo, FIELD_SLA_PAUSADO) == true) {
            return false;
        }
    
        if (esInsert) {
            return true;
        }
    
        if (anteriores == null || nuevo.Id == null) {
            return false;
        }
    
        Lead anterior = anteriores.get(nuevo.Id);
    
        if (anterior == null) {
            return false;
        }
    
        return debeCrearSeguimientoSLAComun(
            nuevo,
            anterior
        );
    }
    
    /*
     * -----------------------------------------------------------------------------
     * CREACIÓN DE SEGUIMIENTO SLA - OPPORTUNITY
     * -----------------------------------------------------------------------------
     */
        private static Boolean debeCrearSeguimientoSLA(
            Opportunity nuevo,
            Map<Id, Opportunity> anteriores,
            Boolean esInsert
        ) {
        
            if (nuevo == null) {
                return false;
            }
        
            if (getBoolean(nuevo, FIELD_SLA_PAUSADO) == true) {
                return false;
            }
        
            if (esInsert) {
                return true;
            }
        
            if (anteriores == null || nuevo.Id == null) {
                return false;
            }
        
            Opportunity anterior = anteriores.get(nuevo.Id);
        
            if (anterior == null) {
                return false;
            }
        
            return debeCrearSeguimientoSLAComun(
                nuevo,
                anterior
            );
        }
        
        /*
         * -----------------------------------------------------------------------------
         * LÓGICA COMÚN DE CREACIÓN DE SEGUIMIENTO
         * -----------------------------------------------------------------------------
         */
        private static Boolean debeCrearSeguimientoSLAComun(
            SObject nuevo,
            SObject anterior
        ) {
        
            if (nuevo == null || anterior == null) {
                return false;
            }
        
            return
                getDatetime(nuevo, FIELD_SLA_LIMITE) !=
                getDatetime(anterior, FIELD_SLA_LIMITE) ||
                getString(nuevo, FIELD_SLA_ESTATUS) !=
                getString(anterior, FIELD_SLA_ESTATUS) ||
                getString(nuevo, FIELD_SLA_CADENCIA) !=
                getString(anterior, FIELD_SLA_CADENCIA);
        }
    
        /*
         * =====================================================================================
         * HELPERS
         * =====================================================================================
         */
        private static String obtenerRamo(SObject registro) {
    
            String ramo = getString(registro, 'Ramo__c');
    
            if (!String.isBlank(ramo)) {
                return ramo;
            }
    
            return getString(registro, 'Tech_Ramo__c');
        }
    
        private static String obtenerProducto(SObject registro) {
    
            String producto = getString(registro, 'Producto_Interes__c');
    
            if (!String.isBlank(producto)) {
                return producto;
            }
    
            return getString(registro, 'Tech_Producto_Interes__c');
        }
    
        public static Boolean campoExiste(Schema.SObjectType tipo, String campo) {
    
            if (tipo == null || String.isBlank(campo)) {
                return false;
            }
    
            return tipo.getDescribe().fields.getMap().containsKey(campo);
        }
    
        public static void agregarCampoSiExiste(
            Schema.DescribeSObjectResult describe,
            List<String> campos,
            String campo
        ) {
    
            if (describe == null || campos == null || String.isBlank(campo)) {
                return;
            }
    
            if (
                describe.fields.getMap().containsKey(campo) &&
                !campos.contains(campo)
            ) {
                campos.add(campo);
            }
        }
    
        public static void putIfExists(SObject registro, String campo, Object valor) {

            if (registro == null || String.isBlank(campo)) {
                return;
            }

            Map<String, Schema.SObjectField> campos =
                registro.getSObjectType().getDescribe().fields.getMap();

            if (!campos.containsKey(campo)) {
                return;
            }

            // CORRECCIÓN DE SEGURIDAD: Validación de tipos para evitar "Illegal assignment from Datetime to Date"
            if (valor instanceof Datetime) {
                Schema.DisplayType tipoCampo = campos.get(campo).getDescribe().getType();
                if (tipoCampo == Schema.DisplayType.DATE) {
                    valor = ((Datetime)valor).date(); // Convertimos Datetime a Date si el campo lo exige
                }
            }

            registro.put(campo, valor);
        }
    
        public static Object getValue(SObject registro, String campo) {
    
            if (registro == null || String.isBlank(campo)) {
                return null;
            }
    
            try {
                return registro.get(campo);
            } catch (Exception e) {
                return null;
            }
        }
    
        public static Id getId(SObject registro, String campo) {
    
            Object valor = getValue(registro, campo);
    
            if (valor == null) {
                return null;
            }
    
            try {
                return (Id) valor;
            } catch (Exception e) {
                return null;
            }
        }

    public static String getString(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return null;
        }

        return String.valueOf(valor);
    }

    public static Decimal getDecimal(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return null;
        }

        if (valor instanceof Decimal) {
            return (Decimal) valor;
        }

        try {
            return Decimal.valueOf(String.valueOf(valor));
        } catch (Exception e) {
            return null;
        }
    }

    public static Boolean getBoolean(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return false;
        }

        if (valor instanceof Boolean) {
            return (Boolean) valor;
        }

        String texto = String.valueOf(valor).trim().toLowerCase();

        return texto == 'true' || texto == 'sí' || texto == 'si';
    }

    public static Datetime getDatetime(SObject registro, String campo) {

        Object valor = getValue(registro, campo);

        if (valor == null) {
            return null;
        }

        if (valor instanceof Datetime) {
            return (Datetime) valor;
        }

        return null;
    }

    private static String normalizar(String valor) {

        if (String.isBlank(valor)) {
            return '';
        }

        return valor.trim().toUpperCase();
    }
}