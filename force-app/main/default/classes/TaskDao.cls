public without sharing class TaskDao extends GenericDao {

    private static final String NWFB_INFO_EMAIL = 'info@nwfurniturebank.org';

    @TestVisible
    private static TaskDao mock;

    public TaskDao() {
    }

    private TaskDao(List<SObject> tasks, Map<Id, SObject> oldTasksById) {
        super(tasks, oldTasksById);
    }
    private TaskDao(List<SObject> tasks) {
        super(tasks);
    }

    public static TaskDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new TaskDao(new List<Task>());
        }
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new TaskDao(objects, oldObjectsById);
        }
    }

    public override void afterInsert() {
        sendSMS();
        createTaskFromSMS();
        recalculateContactAttempts();
        rollup();
    }

    public override void beforeInsert() {
        validateContactPhone();
        createSMSTask();
        updateDueDateField();
    }

    public override void afterUpdate() {
        recalculateContactAttempts();
        rollup();
    }

    @TestVisible
    private void createSMSTask(){
        List<Task> tasks = (List<Task>) this.records;
        List<Task> incomingTasks = new List<Task>();
        Set<String> contactMobilePhoneSet = new Set<String>();

        for (Task task : tasks) {
            if (task.Type != 'SMS') continue;

            if (task.MessageType__c == 'Incoming' && String.isNotBlank(task.MobilePhone__c)) {
                task.Status = 'Completed';
                task.TaskSubtype = 'Task';
                contactMobilePhoneSet.add(task.MobilePhone__c);
                incomingTasks.add(task);
            } else if (task.MessageType__c == 'Outgoing') { 
                task.Subject = task.Subject == null ? task.MessageType__c + ' SMS' : task.Subject;
                task.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('SMS').getRecordTypeId();
            }
        }

        contactMobilePhoneSet.remove(null);

        Map<Id, SObject> contactById = Utils.listToMap(
               'Id',
                ContactSelector.getInstance().getContactsByMobilePhones(contactMobilePhoneSet)
        );

        Map<String, Id> contactMobilePhoneMap = new Map<String, Id>();

        for (Contact contact : (List<Contact>) contactById.values()) {
            contactMobilePhoneMap.put(contact.MobilePhone, contact.Id);
        }

        Map<Id, SObject> serviceByContact = Utils.listToMap(
                'Contact__c',
                ServiceSelector.getInstance().getServicesByContactId(contactById.keySet())
        );

        for (Task task : incomingTasks) {
            task.WhoId = contactMobilePhoneMap.get(task.MobilePhone__c);
            Service__c service = (Service__c) serviceByContact.get(task.WhoId);

            if (service == null) continue;

            task.WhatId = service.Id;
        }
    }

    private void createTaskFromSMS() {
        Set<String> contactMobilePhoneSet = new Set<String>();
        Set<Id> tasksId = new Set<Id>();

        for (Task task : (List<Task>) this.records) {
            if (task.Type != 'SMS') continue;
            if (task.MessageType__c != 'Incoming') continue;
            if (task.MobilePhone__c == null) continue;

            tasksId.add(task.Id);
            contactMobilePhoneSet.add(task.MobilePhone__c);
        }

        List<Task> currentTasks = new TaskSelector().byId(tasksId);


        if (contactMobilePhoneSet == null || contactMobilePhoneSet.isEmpty()) return;

        Map<Id, SObject> contactById = Utils.listToMap(
                'Id',
                ContactSelector.getInstance().getContactsByMobilePhones(contactMobilePhoneSet)
        );

        if (contactById == null) return;

        Map<String, Id> contactByMobilePhone = new Map<String, Id>();

        for (Contact contact : (List<Contact>) contactById.values()) {
            String mobilePhone = contact.MobilePhone.replaceAll('[^0-9]', '');
            contactByMobilePhone.put(mobilePhone, contact.Id);
        }

        List<Service__c> services = ServiceSelector.getInstance().getServicesByContactId(contactById.keySet());
        List<Task> parentTasks = TaskSelector.getInstance().byWhoIdAndType(contactById.keySet());
        Map<Id, Service__c> serviceByContact = new Map<Id, Service__c>();

        for (Service__c service : services){
            serviceByContact.put(service.Contact__c, service);
        }

        List<Task> tasksReadyForUpdate = new List<Task>();

        for (Task task : currentTasks) {
            String taskMobilePhone = task.MobilePhone__c.replaceAll('[^0-9]', '');

            task.Status = 'Completed';
            if (contactByMobilePhone.get(taskMobilePhone) != null) task.WhoId = contactByMobilePhone.get(taskMobilePhone);
            if (serviceByContact.get(task.WhoId) == null) continue;

            task.WhatId = serviceByContact.get(task.WhoId).Id;

            for (Task parentTask : parentTasks) {
                if (parentTask.WhatId != task.WhatId || task.WhoId != parentTask.WhoId) continue;

                parentTask.Read__c = true;
                parentTask.Status = 'Completed';

                tasksReadyForUpdate.add(parentTask);

                break;
            }

            tasksReadyForUpdate.add(task);
        }
        if (tasksReadyForUpdate == null || tasksReadyForUpdate.isEmpty()) return;
        Database.update(tasksReadyForUpdate);
    }

    @TestVisible
    private void sendSMS(){
        Set<Id> contactIds = new Set<Id>();
        Set<Id> serviceIds = new Set<Id>();

        for(Task task : (List<Task>) this.records) {
            serviceIds.add(task.WhatId);
            if (task.WhoId == null) continue;
            contactIds.add(task.WhoId);
        }

        Map<Id,Contact> contactMap = new Map<Id, Contact>(
                ContactSelector.getInstance().getContactsByIds(contactIds)
        );

        Map<Id, Service__c> serviceById = new Map<Id, Service__c>(
                ServiceSelector.getInstance().getServiceByIds(serviceIds)
        );

        for (Task task : (List<Task>) this.records) {
            if (contactMap.get(task.WhoId) == null || contactMap.get(task.WhoId).MobilePhone == null) continue;
            if (task.Type != 'SMS' || task.MessageType__c != 'Outgoing') continue;
            Service__c currentService = serviceById.get(task.WhatId);
            String cityName = currentService.Location__r.City__c;

            if (Test.isRunningTest()) continue;

            System.enqueueJob(
                    new SendSMSQueueable(
                            cityName,
                            contactMap.get(task.WhoId).MobilePhone,
                            task.Description
                    )
            );
        }
    }

    private void recalculateContactAttempts(){
        Map<Id, List<String>> tasksByWhatId = mapTasksByWhatId();
        List<AggregateResult> aggregateResultList = TaskSelector.getInstance().getTaskByTypeAndId(
                tasksByWhatId.keySet(),
                tasksByWhatId.values()
        );

        List<Service__c> services = ServiceSelector.getInstance().getServiceByIds(tasksByWhatId.keySet());
        List<Service__c> servicesToUpdate = getTaskTypeToContactAttemptsMap(aggregateResultList, services);

        TriggerManagement.disableTrigger('ServiceTrigger');
        if (servicesToUpdate.isEmpty() || servicesToUpdate == null) return;
        Database.update(servicesToUpdate, false);
        TriggerManagement.enableTrigger('ServiceTrigger');
    }

    private void validateContactPhone() {
        Set<Id> contactIds = new Set<Id>();

        for (Task task : (List<Task>) this.records) {
            if (task.Type != 'SMS' || task.MessageType__c != 'Outgoing') continue;
            contactIds.add(task.WhoId);
        }

        Map<Id, Contact> contactMap = new Map<Id,Contact>(ContactSelector.getInstance().getContactsByIds(contactIds));

        for (Task task : (List<Task>) this.records) {
            if (task.Type != 'SMS' || task.MessageType__c != 'Outgoing') continue;
            if (!contactMap.containsKey(task.WhoId) || contactMap.get(task.WhoId).MobilePhone != null) continue;
            task.addError('The selected contact does not have a phone number entered.');
        }

    }

    private Map<Id, List<String>> mapTasksByWhatId(){
        Map<Id, List<String>> taskByWhatId = new Map<Id, List<String>>();
		
        for (Task task : (List<Task>) this.records) {
			if (task.WhatId == null) continue;
            taskByWhatId.put(task.WhatId, new List<String>());
        }

        for (Task task : (List<Task>) this.records) {
            if (task.WhatId == null) continue;
            taskByWhatId.get(task.WhatId).add(task.Type);
        }

        return taskByWhatId;
    }

    private List<Service__c> getTaskTypeToContactAttemptsMap(List<AggregateResult> aggregateResultList, List<Service__c> requestList){
        List<Service__c> requestToUpdateList = new List<Service__c>();

        for(Service__c request: requestList){
            Map<String, Integer> TaskTypeToContactAttemptsMap = new Map<String, Integer>();

            for(AggregateResult aggregateResul: aggregateResultList){
                Integer contactAttempts = (Integer) aggregateResul.get('ContactAttemptsTotal__c');
                String type = (String) aggregateResul.get('Type');
                TaskTypeToContactAttemptsMap.put(type, contactAttempts);
            }

            requestToUpdateList.add(updateRequestFields(request, TaskTypeToContactAttemptsMap));
        }
        
        return requestToUpdateList;
    }

    private void updateDueDateField() {
        for (Task task : (List<Task>) this.records) {
            if (task.ActivityDate != null) continue;
            task.ActivityDate = Date.today();
        }
    }

    private static Service__c updateRequestFields(Service__c request, Map<String, Integer> TaskTypeToContactAttemptsMap) {
        request.LogCallAttempts__c = TaskTypeToContactAttemptsMap.get('Call') != null
                ? TaskTypeToContactAttemptsMap.get('Call')
                : request.LogCallAttempts__c;
        request.EmailAttempts__c = TaskTypeToContactAttemptsMap.get('Email') != null
                ? TaskTypeToContactAttemptsMap.get('Email')
                : request.EmailAttempts__c;
        request.OutgoingSMSAttempts__c = TaskTypeToContactAttemptsMap.get('SMS') != null
                ? TaskTypeToContactAttemptsMap.get('SMS')
                : request.OutgoingSMSAttempts__c;
        return request;
    }

    private void rollup() {
        try {
            if (this.records != null && !this.records.isEmpty()) {
                Database.update(dlrs.RollupService.rollup(this.records), false);
            }
        } catch (Exception e){
            System.debug(e.getMessage());
        }
    }
}