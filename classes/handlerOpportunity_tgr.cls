/**
* Deloitte Chile
* @author 			Esteban Heredia
* Project:			IDIEM
* Description:		Clase para los metodos del desencadenador de Oportunidades.
*
* Changes (Version)
* -------------------------------------
*			No.		Date			Author  				Description
*			-----	----------		--------------------	---------------
* @version	1.0		2018-08-17		Esteban Heredia (EH)	Definicion inicial de la clase.
* @version  1.1     2018-10-18		Juan Pablo Hernández	Actualización cambio de estado en las oportunidades.
* @version	1.2		2019-01-16		Camilo Bustamante		Modificada logica para Oportunindades con estado "Cerrada perdida"
*********************************************************************************************************/
public with sharing class handlerOpportunity_tgr {
    public static void ActualizarEstadoCoti(List<Opportunity> newRecords, map<Id, Opportunity> oldMap){
        //Solamente se va a realizar el cambio si existió un cambio a cerrada de la oportunidad
        map<Id, Opportunity> mapOppById = new map<Id, Opportunity>();
        for(Opportunity objOpptemp : newRecords){
            if((objOpptemp.StageName != oldMap.get(objOpptemp.Id).StageName) && (objOpptemp.StageName == 'Cerrada ganada' || objOpptemp.StageName == 'Cerrada perdida')){
                mapOppById.put(objOpptemp.Id, objOpptemp);
            }
        }
        
        List<Quote> lstQuotes = [SELECT Id, OpportunityId, Status 
                                 FROM Quote 
                                 Where OpportunityId IN: mapOppById.KeySet() AND IsSyncing = true];
        List<Quote> lstQuotesUpd = new  List<Quote>();
        
        //Recorremos las cotizaciones para colocarle el mismo valor que la oportunidad
        if(lstQuotes.size() != 0 ){
            for(Quote objQuoteTemp : lstQuotes){
                if(mapOppById.get(objQuoteTemp.OpportunityId).StageName == 'Cerrada ganada' && objQuoteTemp.Status != 'Aceptado'){
                    objQuoteTemp.Status = 'Aceptado';
                    lstQuotesUpd.add(objQuoteTemp);
                }
                else if(mapOppById.get(objQuoteTemp.OpportunityId).StageName == 'Cerrada perdida' && objQuoteTemp.Status != 'Rechazado'){
                    objQuoteTemp.Status = 'Rechazado';
                    lstQuotesUpd.add(objQuoteTemp);
                }
            }
        }
        
        //Actualizamos solo las cotizaciones cambiadas
        if(lstQuotesUpd.size() > 0)
            update lstQuotesUpd;
    }
    
    public static void colocarObjetivo(List<Opportunity> newRecords, map<Id, Opportunity> oldMap){
        map<Id, Opportunity> mapOppById = new map<Id, Opportunity>();
        //Se obtiene la lista de objetivos
        List<Objetivo__c> lstObjetivosTotal =  [SELECT Id, MesA_o__c, Tipo_de_Objetivo__c From Objetivo__c];
        //Se extrae el Id de las oportunidades recibidas por el trigger en la variable newRecords
        Set<Id> ide = new Set<Id>();
        for(Integer i = 0; i < newRecords.size(); i++){
            ide.add(newRecords[I].id);
        }
        //Se obtiene la lista de cotizaciones que estan asociadas a alguna oportunidad que fueron recibidos por el trigger
        List<Quote> lstQuotes = [SELECT Id, OpportunityId, Status, LastModifiedDate, IsSyncing 
                                 FROM Quote
                                 Where OpportunityId IN: ide];
        
        //Itera sobre la lista de Oportunidades recibidas del trigger
        for(Opportunity objOpptemp : newRecords){
            //Se extrae solo aquellas cotizaciones asociadas a la oportunidad objOpptemp
            List<Quote> lstQuotesByOpp = new List<Quote>();
            for(Quote objQuote : lstQuotes){
                if(objQuote.OpportunityId == objOpptemp.Id){
                    lstQuotesByOpp.add(objQuote);
                }
            }
            
            //Se asigna el objetivo asociado a la oportunidad objOpptemp mediante el campo "Fecha_de_ultimo_envio_Cotizacion__c"
            if(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c != oldMap.get(objOpptemp.Id).Fecha_de_ultimo_envio_Cotizacion__c && oldMap.get(objOpptemp.Id).Fecha_de_ultimo_envio_Cotizacion__c != null && objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c != null){
                map<String, Opportunity> mapOppByDate = new map<String, Opportunity>();
                
                //Se obtiene la variable String MesAopp en formato "MesAño" para obtener un objetivo y asignarlo a la oportunidad objOpptemp en base al campo "Fecha_de_ultimo_envio_Cotizacion__c"
                String MesAopp = String.valueOf(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c.month()) + String.valueOf(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c.year());
                
                for(Objetivo__c obj : lstObjetivosTotal){
                    if(obj.Tipo_de_Objetivo__c == 'cotizaciones' && obj.MesA_o__c == MesAopp){
                        objOpptemp.Objetivo_Cotizacion__c = obj.Id;
                    }
                }
            }
            
            //Se realizan acciones especificas por etapas
            //Etapas iniciales no pueden tener objetivos
            if(objOpptemp.StageName == 'Antecedentes'){
                objOpptemp.Objetivo_Cotizacion__c = null;
                objOpptemp.Objetivo__c = null;
            }
            else if(objOpptemp.StageName == 'Elaboración'){
                objOpptemp.Objetivo_Cotizacion__c = null;
                objOpptemp.Objetivo__c = null;
            }
            //Busca si hay cotizaciones para registros en etapa "Propuesta/Cotización Enviada" o "Negociación / Revisión"
            else if(objOpptemp.StageName == 'Propuesta/Cotización Enviada' || objOpptemp.StageName == 'Negociación / Revisión' && objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c == null){
                //Si no hay cotizaciones sincronizadas se envia un error
                if(lstQuotesByOpp.size() == 0){
                    objOpptemp.addError('No existen cotizaciones para esta oportunidad');
                }
            }
            //Realiza acciones para la etapa 'Propuesta/Cotización Enviada'
            else if(objOpptemp.StageName == 'Propuesta/Cotización Enviada' && objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c != null){
                objOpptemp.Objetivo__c = null;
                
                //Se obtiene la variable String MesAopp en formato "MesAño" para obtener un objetivo y asignarlo a la oportunidad objOpptemp en base al campo "Fecha_de_ultimo_envio_Cotizacion__c"
                String MesAopp = String.valueOf(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c.month()) + String.valueOf(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c.year());
                
                //Se realiza la busqueda del objetivo que coincida con MesAopp y el tipo de objetivo sea "Cotizaciones"
                //En caso de no encontrar coincidencia de MesAopp o tipo "Cotizaciones" se enviara un mensaje de error
                for(Objetivo__c objetivos: lstObjetivosTotal){
                    if(objetivos.Tipo_de_Objetivo__c == 'cotizaciones' && objetivos.MesA_o__c == MesAopp){
                        //Verifica que existan cotizaciones sincronizadas y asociadas a la oportunidad objOpptemp
                        if(lstQuotesByOpp.size() != 0){
                            //Se asigna el objetivo encontrado en el campo "Objetivo Cotizacion" de la oportunidad objOpptemp
                            objOpptemp.Objetivo_Cotizacion__c = objetivos.Id;
                            //objQuote.Objetivo__c = objetivos.Id;
                        }
                        else{
                            objOpptemp.addError('No existen cotizaciones asociadas a esta oportunidad');
                        }
                    }
                }
            }
            //Realiza acciones para la etapa 'Negociación / Revisión'
            else if(objOpptemp.StageName == 'Negociación / Revisión' && objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c != null){
                objOpptemp.Objetivo__c = null;
                
                //Se obtiene la variable String MesAopp en formato "MesAño" para obtener un objetivo y asignarlo a la oportunidad objOpptemp en base al campo "Fecha_de_ultimo_envio_Cotizacion__c"
                String MesAopp = String.valueOf(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c.month()) + String.valueOf(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c.year());
                
                //Se realiza la busqueda del objetivo que coincida con MesAopp y el tipo de objetivo sea "Cotizaciones"
                //En caso de no encontrar coincidencia de MesAopp o tipo "Cotizaciones" se enviara un mensaje de error
                for(Objetivo__c objetivos : lstObjetivosTotal){
                    if(objetivos.Tipo_de_Objetivo__c == 'cotizaciones' && objetivos.MesA_o__c == MesAopp){
                        //Verifica que existan cotizaciones sincronizadas y asociadas a la oportunidad objOpptemp
                        if(lstQuotesByOpp.size() != 0){
                            //Se asigna el objetivo encontrado en el campo "Objetivo Cotizacion" de la oportunidad objOpptemp
                            objOpptemp.Objetivo_Cotizacion__c = objetivos.Id;
                        }
                        else{
                            objOpptemp.addError('No existen cotizaciones para esta oportunidad');
                        }
                    }
                }
            }
            //Realiza acciones para la etapa 'Cerrada perdida'
            else if(objOpptemp.StageName == 'Cerrada perdida'){
                //Realizamos validacion para que la oportunidad que ingresa contenga "Fecha de ultimo envio de cotizacion"
                if(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c == null){
                    objOpptemp.addError('No es posible actualizar una oportunidad con estado "Cerrada perdida" sin fecha de último envío de cotización');
                }
                //Pasada la verificacion anterior, realizamos el siguiente paso donde verificamos si la oportunidad contiene un objetivo de cotizacion
                //e intenta agregar uno en caso de no tenerlo.
                else if(objOpptemp.Objetivo_Cotizacion__c == null){
                    //En caso de que el campo este vacio, se inicia la asignacion del objetivo
                    //Se obtiene la variable String MesAopp en formato "MesAño" para obtener un objetivo y asignarlo a la oportunidad objOpptemp en base al campo "Fecha_de_ultimo_envio_Cotizacion__c"
                    String MesAopp = String.valueOf(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c.month()) + String.valueOf(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c.year());
                    for(Objetivo__c objetivos : lstObjetivosTotal){
                        if(objetivos.Tipo_de_Objetivo__c == 'cotizaciones' && objetivos.MesA_o__c == MesAopp){
                            //Se asigna el objetivo encontrado en el campo "Objetivo Cotizacion" de la oportunidad objOpptemp
                            objOpptemp.Objetivo_Cotizacion__c = objetivos.Id;
                        }
                    }
                }
            }
            //Realiza acciones para la etapa 'Cerrada ganada'
            else if(objOpptemp.StageName == 'Cerrada ganada' && objOpptemp.Fecha_de_cierre_del_Negocio__c != null){
                system.debug(lstQuotesByOpp);
                
                //Se obtiene la variable String MesAopp en formato "MesAño" para obtener un objetivo y asignarlo a la oportunidad objOpptemp en base al campo "Fecha_de_cierre_del_Negocio__c"
                String MesAopp = String.valueOf(objOpptemp.Fecha_de_cierre_del_Negocio__c.month()) + String.valueOf(objOpptemp.Fecha_de_cierre_del_Negocio__c.year());
                
                //Se realiza la busqueda del objetivo que coincida con MesAopp, el tipo de objetivo es "Ventas" o "Cotizaciones" y los campos de objetivos cumplan ciertos criterios
                //En caso de el campo "Fecha_de_ultimo_envio_Cotizacion__c" no este definido, se enviara un error
                for(Objetivo__c objetivos : lstObjetivosTotal){
                    //Se evalua si el tipo de objetivo es de "Ventas"
                    if(objetivos.Tipo_de_Objetivo__c == 'Ventas' && objetivos.Tipo_de_Objetivo__c != null && objetivos.MesA_o__c == MesAopp){
                           //Se asigna el objetivo encontrado en el campo "Objetivo Venta" de la oportunidad objOpptemp
                           objOpptemp.Objetivo__c = Objetivos.Id;
                       }
                    //Se evalua si el tipo de objetivo es de "Cotizaciones"
                    else if(objetivos.Tipo_de_Objetivo__c == 'Cotizaciones' && objetivos.Tipo_de_Objetivo__c != null && objOpptemp.Objetivo_Cotizacion__c == null && objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c != null){
                        system.debug(lstQuotesByOpp);
                        //Se obtiene la variable String MesAopp en formato "MesAño" para obtener un objetivo y asignarlo a la oportunidad objOpptemp en base al campo "Fecha_de_ultimo_envio_Cotizacion__c"
                        String MesAoppCot = String.valueOf(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c.month()) + String.valueOf(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c.year());
                        
                        //Se realiza la busqueda de un objetivo de Cotizacion en base a la variable MesAoppCot
                        if(objetivos.MesA_o__c == MesAoppCot){
                            //Se asigna el objetivo encontrado en el campo "Objetivo Cotizacion" de la oportunidad objOpptemp
                            objOpptemp.Objetivo_Cotizacion__c = objetivos.Id;
                        }
                    }
                    else if(objOpptemp.Fecha_de_ultimo_envio_Cotizacion__c == null){
                        objOpptemp.addError('No existe fecha de último envío de cotizacion o no puede ir en blanco');
                    }
                }
            }
        }
    }
}