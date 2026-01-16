trigger PaymentTrigger on Payment__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('PaymentTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
    TriggerHandlerDispatcher.dispatch(PaymentDao.Factory.class);
}