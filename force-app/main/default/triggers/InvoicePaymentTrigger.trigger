trigger InvoicePaymentTrigger on InvoicePayment__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('InvoicePaymentTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
//    if (TriggerManagement.checkStatus('InvoicePaymentTrigger')) return;
    //TriggerHandlerDispatcher.dispatch(PaymentDao.Factory.class);
}