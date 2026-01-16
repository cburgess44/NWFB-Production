trigger CampaignTrigger on Campaign (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('CampaignTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
    TriggerHandlerDispatcher.dispatch(CampaignDao.Factory.class);
}