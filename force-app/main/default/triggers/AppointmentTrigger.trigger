trigger AppointmentTrigger on Appointment__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('AppointmentTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
    TriggerHandlerDispatcher.dispatch(Appointment.Factory.class);
}