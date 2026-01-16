/**
 * Created by Gustavo on 22/09/23.
 */

public without sharing class TriggerManagement {
    private static final Map<String, Boolean> TRIGGER_STATUS = new Map<String, Boolean>();

    public static void disableTrigger(String triggerName) {
        TRIGGER_STATUS.put(triggerName, true);
    }

    public static void enableTrigger(String triggerName) {
        TRIGGER_STATUS.put(triggerName, false);
    }

    public static Boolean checkStatus(String triggerName) {
        Boolean triggerStatus = TRIGGER_STATUS.get(triggerName);
        return triggerStatus;
    }
}