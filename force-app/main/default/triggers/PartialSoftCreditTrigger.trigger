/**
 * Created by Gustavo on 20/03/24.
 */

trigger PartialSoftCreditTrigger on npsp__Partial_Soft_Credit__c (before insert, before update, before delete, after insert, after update, after delete) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('PartialSoftCreditTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
    TriggerHandlerDispatcher.dispatch(PartialSoftCreditDao.Factory.class);
}