/**
* Deloitte Chile
* @author 			Esteban Heredia
* Project:			IDIEM
* Description:		Clase de prueba para los metodos del desencadenador de Oportunidades.
*
* Changes (Version)
* -------------------------------------
*			No.		Date			Author  				Description
*			-----	----------		--------------------	---------------
* @version	1.0		2018-09-02		Esteban Heredia (EH)	Definicion inicial de la clase.
*********************************************************************************************************/
@IsTest
public with sharing class handlerOpportunity_tst 
{
	Public Static Account objAcc;
	Public Static Opportunity objOpp;
	Public Static Quote objCot;
	Public Static Objetivo__c objObjVentas;
    Public Static Objetivo__c objObjCotizaciones;
	
	public static void createdData()
    {
       objAcc = new Account();
       objAcc.Name = 'TestAcc';
	   Insert objAcc;
       objOpp = new Opportunity();
       objOpp.Name = 'TestOpp';
       objOpp.StageName = 'Elaboración';
       objOpp.CloseDate = system.today();
       objOpp.AccountId = objAcc.Id;
       objOpp.Division__c = 'DIO';
       objOpp.Seccion__c = '1789';
       objOpp.Unidad__c = '2123';
       objOpp.Fecha_de_ultimo_envio_Cotizacion__c = system.today().addDays(1);
       Insert objOpp;
       objCot = new Quote();
       objCot.Name = 'TestQuote';
       objCot.OpportunityId = objOpp.Id;
       objCot.Status = 'En elaboración';
       Insert objCot;
       objObjVentas = new Objetivo__c();
       objObjVentas.Name = String.valueOf(system.today().month()) + String.valueOf(system.today().year()) + 'Ventas';
       objObjVentas.Mes__c = String.valueOf(system.today().month());
       objObjVentas.A_o__c = String.valueOf(system.today().year());
       objObjVentas.Tipo_de_Objetivo__c = 'ventas';
       insert objObjVentas;
       objObjCotizaciones = new Objetivo__c();
       objObjCotizaciones.Name = objObjVentas.Name = String.valueOf(system.today().month()) + String.valueOf(system.today().year()) + 'Cotizaciones';
       objObjCotizaciones.Mes__c = String.valueOf(system.today().month());
       objObjCotizaciones.A_o__c = String.valueOf(system.today().year());
       objObjCotizaciones.Tipo_de_Objetivo__c = 'Cotizaciones';
       insert objObjCotizaciones;
    }
    @istest
    private static void testOppSinCotizaciones()
    {
       objAcc = new Account();
       objAcc.Name = 'TestAcc2';
	   Insert objAcc;
       objOpp = new Opportunity();
       objOpp.Name = 'TestOpp2';
       objOpp.StageName = 'Elaboración';
       objOpp.CloseDate = system.today();
       objOpp.AccountId = objAcc.Id;
       objOpp.Division__c = 'DIO';
       objOpp.Seccion__c = '1789';
       objOpp.Unidad__c = '2123';
       Insert objOpp;
       objObjVentas = new Objetivo__c();
       objObjVentas.Mes__c = String.valueOf(system.today().month());
       objObjVentas.A_o__c = String.valueOf(system.today().year());
       objObjVentas.Tipo_de_Objetivo__c = 'ventas';
       insert objObjVentas;
       objObjCotizaciones = new Objetivo__c();
       objObjCotizaciones.Mes__c = String.valueOf(system.today().month());
       objObjCotizaciones.A_o__c = String.valueOf(system.today().year());
       objObjCotizaciones.Tipo_de_Objetivo__c = 'Cotizaciones';
       insert objObjCotizaciones;
	   Test.StartTest();
	   objOpp.StageName = 'Negociación / Revisión';
       objOpp.Fecha_de_ultimo_envio_Cotizacion__c = null;
	   Database.SaveResult result = Database.update(objOpp, false);
       System.assert(!result.isSuccess());
       System.assert(result.getErrors().size() > 0);
       System.assertEquals('No existen cotizaciones para esta oportunidad',
                             result.getErrors()[0].getMessage());
        
       objOpp.StageName = 'Propuesta/Cotización Enviada';
       objOpp.Fecha_de_ultimo_envio_Cotizacion__c = null;
	   Database.SaveResult result2 = Database.update(objOpp, false);
       System.assert(!result2.isSuccess());
       System.assert(result2.getErrors().size() > 0);
       System.assertEquals('No existen cotizaciones para esta oportunidad',
                             result2.getErrors()[0].getMessage());
	   Test.stopTest();
    }
    @istest
    private static void testStages()
    {
	   createdData();
	   Test.StartTest();
        	objOpp.StageName = 'Antecedentes';
	   		update 	objOpp;
        	objOpp.StageName = 'Elaboración';
	   		update 	objOpp;
        	objOpp.StageName = 'Propuesta/Cotización Enviada';
        	objOpp.Fecha_de_ultimo_envio_Cotizacion__c = system.today().addDays(5);
	   		update 	objOpp;
        	objOpp.StageName = 'Negociación / Revisión';
        	objOpp.Fecha_de_ultimo_envio_Cotizacion__c = null;
	   		update 	objOpp;
        	objOpp.StageName = 'Negociación / Revisión';
        	objOpp.Fecha_de_ultimo_envio_Cotizacion__c = system.today();
	   		update 	objOpp;
       Test.stopTest();
    }
	@istest
    private static void methodOne()
    {
	   createdData();
	   Test.StartTest();
        	objOpp.StageName = 'Cerrada ganada';
	   		objOpp.Fecha_de_cierre_del_Negocio__c = system.today();
	   		objOpp.Fecha_primera_facturaci_on__c = system.today();
	   		objOpp.Cuotas_de_facturacion__c = 2;       	
        	update 	objOpp;
        	objOpp.Fecha_de_ultimo_envio_Cotizacion__c = null;
        	Database.SaveResult result2 = Database.update(objOpp, false);
       		System.assert(!result2.isSuccess());
       		System.assert(result2.getErrors().size() > 0);
       		System.assertEquals('No existe fecha de último envío de cotizacion o no puede ir en blanco',
                             result2.getErrors()[0].getMessage());
        	objOpp.StageName = 'Cerrada perdida';
	   		objOpp.Fecha_de_cierre_del_Negocio__c = system.today();
	   		objOpp.Fecha_primera_facturaci_on__c = system.today();
        	objOpp.Motivo_del_rechazo__c = 'No Cotizado';
	   		objOpp.Cuotas_de_facturacion__c = 2;
	   		update 	objOpp;
	   Test.stopTest();
    }
    
	static testMethod void testOppTriggerBulk(){
		
		//First, prepare 200 opportunity for the test data
		objAcc = new Account();
        objAcc.Name = 'TestAccA';
        Insert objAcc;

        objObjVentas = new Objetivo__c();
        objObjVentas.Name = String.valueOf(system.today().month()) + String.valueOf(system.today().year()) + 'Ventas';
        objObjVentas.Mes__c = String.valueOf(system.today().month());
        objObjVentas.A_o__c = String.valueOf(system.today().year());
        objObjVentas.Tipo_de_Objetivo__c = 'ventas';
        insert objObjVentas;
        
		Opportunity[] oppToCreate = new Opportunity[]{};
        Quote[] quoteToCreate = new Quote[]{};
		for(Integer x=0; x<10;x++){
		    objOpp = new Opportunity();
            objOpp.Name = 'TestOpp'+x;
            objOpp.StageName = 'Cerrada ganada';
            objOpp.CloseDate = system.today();
            objOpp.AccountId = objAcc.Id;
            objOpp.Division__c = 'DIO';
            objOpp.Seccion__c = '1789';
            objOpp.Unidad__c = '2123';
            objOpp.Fecha_de_ultimo_envio_Cotizacion__c = system.today().addDays(1);
            objOpp.Fecha_de_cierre_del_Negocio__c = system.today();
            objOpp.Cuotas_de_facturacion__c = 1;
            objOpp.Fecha_primera_facturaci_on__c = system.today();
		    oppToCreate.add(objOpp);
            //quoteToCreate.add(objCot);
		}
		
		//Now insert data causing an contact trigger to fire. 
		Test.startTest();
		insert oppToCreate;
        system.debug(oppToCreate.get(1));
        //insert objCot;
        for(Integer i=0; i<oppToCreate.size();i++){
            objCot = new Quote();
            objCot.Name = 'TestQuote' + i;
            objCot.OpportunityId = oppToCreate[i].id;
            objCot.Status = 'En elaboración';
            oppToCreate[i].Objetivo__c = objObjVentas.id;
            quoteToCreate.add(objCot);
        }
        insert quoteToCreate;
        update oppToCreate;
        system.debug(oppToCreate.get(1));
		Test.stopTest();	
	}	
}