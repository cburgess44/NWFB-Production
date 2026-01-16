/**
 * Created by Eric Solari on 02/05/2023.
 */

trigger DispatcherExceptionTrigger on DispatcherException__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('DispatcherExceptionTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
    TriggerHandlerDispatcher.dispatch(TripExceptionDao.Factory.class);
}