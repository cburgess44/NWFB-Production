/**
 * Created by Gustavo on 14/02/23.
 */

trigger ServiceItemTrigger on ServiceItem__c (after insert, after update, after delete, before update, before insert) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('ServiceItemTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
    TriggerHandlerDispatcher.dispatch(ServiceItemDao.Factory.class);
}