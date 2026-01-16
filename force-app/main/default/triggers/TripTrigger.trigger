trigger TripTrigger on Trip__c (before insert, before update, after insert, after update, after delete) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('TripTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
    TriggerHandlerDispatcher.dispatch(TripDao.Factory.class);
}