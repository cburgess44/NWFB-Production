public without sharing class Appointment extends GenericDao {

    @TestVisible
    private static Appointment mock;
    private static final String STATUS_SCHEDULED = 'Scheduled';
    private static final String STATUS_CANCELLED = 'Cancelled';
    private static final String STATUS_DELIVERY = 'Delivery';
    private static final String STATUS_COMPLETED = 'Completed';
    private static final String STATUS_EXPIRED = 'Expired';

    public Appointment() {
    }

    private Appointment(List<SObject> requests, Map<Id, SObject> oldRequestsById) {
        super(requests, oldRequestsById);
    }

    private Appointment(List<SObject> requests) {
        super(requests);
    }

    public static Appointment getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new Appointment(new List<Task>());
        }
    }

    public override void afterInsert() {
        sendSMSToServiceContact();
//        sendConfirmationBasedOnStatus();
        updateServiceStatusAndAppointment();
        rollup();
    }

    public override void afterUpdate() {
//        sendConfirmationBasedOnStatus();
        rollup(); 
    }

    public override void beforeUpdate() {
        updateCaseworkerEmailField();
    }

    public override void beforeInsert() {
        updateCaseworkerEmailField();
    }

    public override void afterDelete() {
        rollup();
    }

    private void rollup() {
        try {
            if (this.records != null && !this.records.isEmpty()) {
                Database.update(dlrs.RollupService.rollup(this.records), false);
            }
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

    }

    public void updateServiceStatusAndAppointment() {
        Map<Id, Id> mapAppointmentServices = new Map<Id, Id>();
        Map<Id, Appointment__c> serviceIdToAppointmentMap = new Map<Id, Appointment__c>();

        for (Appointment__c appointment : (List<Appointment__c>) this.records) {
            mapAppointmentServices.put(appointment.Service__c, appointment.Id);
            serviceIdToAppointmentMap.put(appointment.Service__c, appointment);
        }

        Map<Id, Appointment__c> appointmentsByServiceId = AppointmentSelector.newInstance().getOldestScheduledAppointmentByServiceId(mapAppointmentServices);

        List<Service__c> servicesToUpdate = ServiceSelector.getInstance().getServiceByIds(mapAppointmentServices.keySet());
        List<Appointment__c> appointmentsToCancel = new List<Appointment__c>();

        for (Service__c service : servicesToUpdate) {

            if (service?.RecordType?.DeveloperName == null) continue;
            if (service.RecordType.DeveloperName != 'ClientRequest') continue;

            if (!appointmentsByServiceId.isEmpty()) {
                service.CurrentAppointment__c = appointmentsByServiceId?.get(service.Id).Id;

                appointmentsToCancel.add(
                        new Appointment__c(
                                Id = service.CurrentAppointment__c,
                                Status__c = 'Cancelled'
                        )
                );
            } else {
                service.CurrentAppointment__c = mapAppointmentServices?.get(service.Id);
            }

            if (service.Status__c != STATUS_DELIVERY && service.Status__c != STATUS_CANCELLED && service.Status__c != STATUS_COMPLETED && service.Status__c != STATUS_EXPIRED){
                service.Status__c = STATUS_SCHEDULED;
            }
            service.LastAppointmentDate__c = serviceIdToAppointmentMap?.get(service.Id).Date__c;
        }
        TriggerManagement.disableTrigger('AppointmentTrigger');
        TriggerManagement.disableTrigger('ServiceTrigger');
        update appointmentsToCancel;
        update servicesToUpdate;
        TriggerManagement.enableTrigger('AppointmentTrigger');
        TriggerManagement.enableTrigger('ServiceTrigger');
    }

//    public void sendConfirmationBasedOnStatus() {
//        Set<Id> serviceIds = new Set<Id>();
//
//        for (Appointment__c  appointment : (List<Appointment__c>) this.records) {
//            serviceIds.add(appointment.Service__c);
//        }
//
//        List<String> emailTemplateNames = new List<String>{
//                'RequestNotFoundEmailTemplate',
//                'ClientMissedTheirAppointmentTemplate',
//                'ClientShoppingAppointmentScheduled',
//                'CaseWorkerAppointmentScheduledEmail'
//        };
//
//        Map<String, EmailTemplate> emailTemplatesByNameMap = EmailTemplateSelector.getInstance().getEmailTemplatesByDeveloperNames(emailTemplateNames);
//        Map<String, OrgWideEmailAddress> addressToOrgWideEmail = OrgWideEmailAddressSelector.getInstance().getOrgWideEmailAddressByEmailAddress(
//                'clientservices@nwfurniturebank.org'
//        );
//
//        Map<Id, Service__c> serviceMap = new Map<Id, Service__c>(
//                ServiceSelector.getInstance().getServiceByIdsAndItemsByCategory(serviceIds)
//        );
//
//        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
//        List<Task> tasksToCreate = new List<Task>();
//
//        if (addressToOrgWideEmail == null) return;
//        Id orgWideEmailId = addressToOrgWideEmail.get('clientservices@nwfurniturebank.org').Id;
//
//        for (Appointment__c appointment : (List<Appointment__c>) this.records) {
//            Service__c service = serviceMap.get(appointment.Service__c);
//            String contactPreferredEmail;
//
//            if (service != null) {
//                if (service.Contact__r.npe01__Preferred_Email__c == null || service.Contact__r.npe01__Preferred_Email__c == 'Personal') {
//                    contactPreferredEmail = service.Contact__r.npe01__HomeEmail__c;
//                } else if (service.Contact__r.npe01__Preferred_Email__c == 'Work') {
//                    contactPreferredEmail = service.Contact__r.npe01__WorkEmail__c;
//                } else {
//                    contactPreferredEmail = service.Contact__r.npe01__AlternateEmail__c;
//                }
//
//                if (contactPreferredEmail == '') {
//                    appointment.addError('No preferred email on contact');
//                    continue;
//                }
//            }
//
//            try {
//                Boolean isOneDayBefore = Date.today().daysBetween(appointment.Date__c) == 1 && appointment.Date__c < Date.today();
//
//                if (isOneDayBefore) tasksToCreate.add(createEmailTask(appointment, service, null));
//
//                if (appointment.Status__c == 'Scheduled') {
//                    if (service == null) {
//                        emailsToSend.add(
//                                createEmail(
//                                        emailTemplatesByNameMap.get('RequestNotFoundEmailTemplate'),
//                                        appointment.OwnerId,
//                                        appointment.Owner.Email,
//                                        orgWideEmailId,
//                                        appointment.Id
//                                )
//                        );
//                        tasksToCreate.add(createEmailTask(appointment, service, null));
//                        continue;
//                    }
//
//                    emailsToSend.add(
//                            createEmail(
//                                    emailTemplatesByNameMap.get('ClientShoppingAppointmentScheduled'),
//                                    service.Contact__c,
//                                    contactPreferredEmail,
//                                    orgWideEmailId,
//                                    appointment.Id
//                            )
//                    );
//
//                    tasksToCreate.add(createEmailTask(appointment, service, null));
//
//                    emailsToSend.add(
//                            createEmail(
//                                    emailTemplatesByNameMap.get('CaseWorkerAppointmentScheduledEmail'),
//                                    service.Caseworker__c,
//                                    appointment.CaseworkerEmail__c,
//                                    orgWideEmailId,
//                                    appointment.Id
//                            )
//                    );
//
//                    continue;
//                }
//
//                if (appointment.Status__c == 'No Show') {
//                    tasksToCreate.add(createEmailTask(appointment, service, null));
//
//                    emailsToSend.add(
//                            createEmail(
//                                    emailTemplatesByNameMap.get('ClientMissedTheirAppointmentTemplate'),
//                                    service.Contact__c,
//                                    contactPreferredEmail,
//                                    orgWideEmailId,
//                                    appointment.Id
//                            )
//                    );
//
//                    continue;
//                }
//            } catch (Exception e) {
//                System.debug(e.getMessage());
//            }
//
//        }
//
//        sendEmails(emailsToSend, tasksToCreate);
//        Database.insert(tasksToCreate, false);
//    }

    private static Messaging.SingleEmailMessage createEmail(EmailTemplate emailTemplatesByNameMap, Id targetId, String email, Id orgWideEmailAddressId, String whatId) {
        List<String> toEmailAddressList = new List<String>{email};

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        mail.setTemplateId(emailTemplatesByNameMap.Id);
        mail.setToAddresses(toEmailAddressList);
        mail.setTargetObjectId(targetId);
        mail.setWhatId(whatId);
        mail.setSaveAsActivity(false);

        if (orgWideEmailAddressId == null) mail.setOrgWideEmailAddressId(orgWideEmailAddressId);

        return mail;
    }

    private static void sendEmails(List<Messaging.SingleEmailMessage> emailsToSend, List<Task> tasksToCreate) {
        List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailsToSend);
        registerMessaging(results, tasksToCreate);

    }

    private static void registerMessaging(List<Messaging.SendEmailResult> results, List<Task> tasksToCreate) {
        for (Messaging.SendEmailResult result : results) {

            if (result.getErrors().isEmpty()) continue;

            for (Messaging.SendEmailError error : result.getErrors()) {
                tasksToCreate.add(createEmailTask(null, null, error));
            }
        }
    }

    public static Task createEmailTask(Appointment__c appointment, Service__c service, Messaging.SendEmailError error) {
        String description = error != null
                ? 'The email related to the ' + service.Contact__r.Name + ' bounced. Error: ' + error.getMessage()
                : 'A Confirmation Email has been sent.';

        Task task = new Task(
                Priority = 'Normal',
                Subject = error == null ? appointment.ServiceType__c : 'Error sending email confirmation',
                ActivityDate = Date.today(),
                Status = 'Completed',
                RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sent Email').getRecordTypeId(),
                TaskSubtype = 'Email',
                Type = 'Email',
                WhatId = service.Id,
                WhoId = service.Contact__c,
                OwnerId = service.OwnerId,
                Description = description
        );

        return task;
    }

    private void sendSMSToServiceContact() {
        Set<Id> serviceIds = new Set<Id>();

        for (Appointment__c app : (List<Appointment__c>) records) {
            if (app.Status__c != STATUS_SCHEDULED) continue;
            serviceIds.add(app.Service__c);
        }

        Map<Id, SObject> serviceById = Utils.listToMap('Id', new ServiceSelector().getServiceByIds(serviceIds));
        List<Task> pendingTasks = new List<Task>();

        for (Appointment__c app : (List<Appointment__c>) records) {
            if (app.Status__c != STATUS_SCHEDULED) continue;

            Service__c service = (Service__c) serviceById.get(app.Service__c);
            String appointmentDateString = app.Date__c.month() + '/' + app.Date__c.day() + '/' + app.Date__c.year();

            if (service == null) continue;

            String smsMessage = 'Your shopping appointment is scheduled for ' + appointmentDateString + ' ' + app.Time__c + ' at NW Furniture Bank.' +
            'We are located at ' + app.LocationAddress__c +
            ' ' +
            'Tacoma: Enter through the orange door for check-in \n' +
            'Vancouver: Enter through the door with the orange sign for check-in\n' +
            ' ' +
            'Please bring photo ID for check in.\n' +
            'If you are bringing your own transportation for your items, bring enough vehicle space to take everything home in 1 trip.\n' +
            'Please have your vehicle(s) present at the start of your appointment.';


//            String smsMessage = 'Your shopping appointment is scheduled for '
//                    + appointmentDateString
//                    + ' '
//                    + app.Time__c + ' at NW Furniture Bank.\n' +
//                    'We are located at ' + app.LocationAddress__c + '\n' +
//                    'When you arrive, please come around the back of building and enter through the orange door for check-in.';
//

            pendingTasks.add(
                    new Task(
                            Subject = 'Appointment ' + app.Name + ' Scheduled',
                            WhatId = app.Service__c,
                            WhoId = service.Contact__c,
                            Priority = 'Normal',
                            Status = 'Completed',
                            ActivityDate = Date.today(),
                            Description = smsMessage
                    )
            );

            System.enqueueJob(
                    new SendSMSQueueable(
                            service.Location__r.City__c,
                            service.Contact__r.MobilePhone,
                            smsMessage
                    )
            );
        }

        if (pendingTasks == null || pendingTasks.isEmpty()) return;

        TriggerManagement.disableTrigger('TaskTrigger');
        insert pendingTasks;
    }

    private void updateCaseworkerEmailField() {
        Set<Id> serviceIds = new Set<Id>();

        for (Appointment__c app : (List<Appointment__c>) records) {
            if (app.Service__c == null) continue;
            serviceIds.add(app.Service__c);
        }

        Map<Id, SObject> serviceById = Utils.listToMap(
                'Id',
                new ServiceSelector().getServiceByIds(serviceIds)
        );

        for (Appointment__c app : (List<Appointment__c>) records) {
            if (app.Service__c == null) continue;

            Service__c currentService = (Service__c) serviceById.get(app.Service__c);

            if (currentService.Caseworker__c == null) continue;

            app.CaseworkerEmail__c = currentService.Caseworker__r.Email;
        }
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new Appointment(objects, oldObjectsById);
        }
    }
}