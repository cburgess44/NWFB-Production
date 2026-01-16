/**
 * Created by Gustavo on 14/03/23.
 */

trigger ContactTrigger on Contact (before insert, before update, before delete, after insert, after update, after delete) {
    Boolean triggerDisabled = TriggerManagement.checkStatus('ContactTrigger');
    if (triggerDisabled != null && triggerDisabled) return;
    TriggerHandlerDispatcher.dispatch(ContactDao.Factory.class);
}