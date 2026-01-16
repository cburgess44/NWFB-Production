/**
 * Created by Gustavo on 06/03/24.
 */

trigger OpportunityContactRoleTrigger on OpportunityContactRole (before insert, before update, before delete, after insert, after update, after delete) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('OpportunityContactRoleTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
    TriggerHandlerDispatcher.dispatch(OpportunityContactRoleDao.Factory.class);
}