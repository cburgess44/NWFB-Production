trigger InvoiceItemTrigger on InvoiceItem__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('InvoiceItemTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
    TriggerHandlerDispatcher.dispatch(InvoiceItemDao.Factory.class);
}