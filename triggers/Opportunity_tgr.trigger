/**
* Deloitte Chile
* @author 			Esteban Heredia
* Project:			IDIEM
* Description:		Desencadenador para el objeto de Oportunidades.
*
* Changes (Version)
* -------------------------------------
*			No.		Date			Author  				Description
*			-----	----------		--------------------	---------------
* @version	1.0		2018-08-17		Esteban Heredia (EH)	Definicion inicial de la clase.
*********************************************************************************************************/
trigger Opportunity_tgr on Opportunity (after delete, after insert, after undelete, 
										after update, before delete, before insert, before update) 
{
	if(Trigger.isAfter)
	{
		if(Trigger.isUpdate) 
		{
			handlerOpportunity_tgr.ActualizarEstadoCoti(Trigger.New,Trigger.oldMap);
		}
	}
	if(Trigger.isBefore)
	{
		if(Trigger.isUpdate) 
		{
			handlerOpportunity_tgr.colocarObjetivo(Trigger.new,Trigger.oldMap);   
		}

	}
    
}