/**
 * Created by Gustavo on 15/03/24.
 */

trigger RecurringDonationTrigger on npe03__Recurring_Donation__c (before insert, before update, before delete, after insert, after update, after delete) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('RecurringDonationTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
    TriggerHandlerDispatcher.dispatch(RecurringDonationDao.Factory.class);
}