/**
 * Created by Gustavo on 01/03/23.
 */

trigger LocationTrigger on Location__c (before insert, before update, before delete, after insert, after update, after delete) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('LocationTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
    TriggerHandlerDispatcher.dispatch(LocationDao.Factory.class);
}