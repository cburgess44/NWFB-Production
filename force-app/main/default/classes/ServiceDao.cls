public without sharing class ServiceDao extends GenericDao {

    @TestVisible
    private static ServiceDao mock;

    public ServiceDao() {
    }

    private ServiceDao(List<SObject> services, Map<Id, SObject> oldServicesById) {
        super(services, oldServicesById);
    }

    private ServiceDao(List<SObject> services) {
        super(services);
    }

    public static ServiceDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new ServiceDao(new List<Service__c>());
        }
    }

    public override void afterInsert() {
        sendEmailBasedOnStatus();
        countAmountOfRequestInTheLastYear();
        callSendInvoiceForCaseworkerAPContact();
        rollup();
    }

    public override void afterUpdate() {
        sendTripScheduledNotification();
        sendEmailBasedOnStatus();
        countAmountOfRequestInTheLastYear();
        sendScheduledPickupMessage();
        sendReceiptPaymentEmail();
        rollup();
    }
    public override void afterDelete() {
        rollup();
    }

    public override void beforeInsert() {
        adjustTruckNotes();
        setServiceName();
        setAgreementText();
        setDefaultLocationBasedOnUser();
        setTaxPercentage();
        setAreaByZipCode();
        setFeeAmount();
        setPossibleDeleteDate();
        //setTotalTaxableAmount();
        //calculateTotalTaxAmount();
    }

    public override void beforeUpdate() {
        adjustTruckNotes();
        setNewStatus();
        setPossibleDeleteDate();
        setServiceName();
        setAreaByZipCode();
        blockRequestStatusChange();
        setTaxPercentage();
        setFeeAmount();
        //setTotalTaxableAmount();
        calculateTotalTaxAmount();
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

    @TestVisible
    private void setPossibleDeleteDate() {
        for (Service__c service : (List<Service__c>) this.records) {
            Date createdDate = service.CreatedDate != null ? service.CreatedDate.date() : System.today();
            if (service.NumberOfScheduledAppointments__c > 0) {
                service.DeletionDate__c = null;
            } else {
                service.DeletionDate__c = createdDate.addDays(90);
            }
        }
    }

    private void sendReceiptPaymentEmail() {
        Set<Id> serviceIds = new Set<Id>();

        for (Service__c service : (List<Service__c>) records) {
            Service__c oldService = (Service__c) oldRecordsById.get(service.Id);

            if (oldService.BalanceDue__c == service.BalanceDue__c) continue;
            if (oldService.TotalPaid__c == service.TotalPaid__c) continue;

            serviceIds.add(service.Id);
        }

        Map<Id, SObject> serviceById = Utils.listToMap(
                'Id',
                new ServiceSelector().getServiceByAndLastPayment(serviceIds)
        );

        Set<Id> paymentIds = new Set<Id>();

        for (Service__c service : (List<Service__c>) records) {
            Service__c currentService = (Service__c) serviceById.get(service.Id);
            if (currentService == null || currentService.Payments__r.isEmpty()) continue;
            paymentIds.add(currentService.Payments__r[0].Id);
        }

        if (paymentIds == null || paymentIds.isEmpty()) return;

        PaymentReceiptEmailSender.send(paymentIds);
    }

    @TestVisible
    private void setAreaByZipCode() {
        Set<String> serviceZipCodes = new Set<String>();

        for (Service__c service : (List<Service__c>) this.records) {
            if (service.Zip__c == null) continue;
            serviceZipCodes.add(service.Zip__c);
        }

        if (serviceZipCodes.isEmpty()) return;

        List<Area__c> areas = AreaSelector.getInstance().getAreaByZipCode(serviceZipCodes);

        if (areas.isEmpty()) return;

        for (Service__c service : (List<Service__c>) this.records) {
            for (Area__c area : areas) {
                if (service.Zip__c != area.ZipCode__c) continue;
                service.Area__c = area.Id;
            }
        }
    }

    private void sendTripScheduledNotification() {
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();
        OrgWideEmailAddress clientServiceEmailAddress = new OrgWideEmailAddressSelector().getOrgWideEmailAddress('info@nwfurniturebank.org');

        for (Service__c service : (List<Service__c>) records) {
            Service__c oldService = (Service__c) oldRecordsById.get(service.Id);
            if (service.Status__c != 'Shopping' || oldService.Status__c != 'Routing') continue;
            if (service.RecordTypeName__c != 'ClientRequest') continue;
            if (service.SubType__c != 'Delivery') continue;
            if (service.Contact__c == null) continue;

            String timeframeRanged = service.TripTimeFrame__c == 'Morning' ? '9am-2pm' : '2pm-5pm';

            String smsMessage = 'Your NW Furniture Bank delivery has been scheduled for '
                    + service.TripDate__c.format() + ' between ' + timeframeRanged +
                    '. You will receive a text message when our truck is on its way.';

            String emailBody = 'Dear ' + service.ContactFirstName__c +'<br><br> '+
                    'Your NW Furniture Bank delivery has been scheduled for '
                    + service.TripDate__c.format() + ' between ' + timeframeRanged +
                    '. You will receive a text message when our truck is on its way.<br><br>' +
                    'If you have any question, please email us at info@nwfurniturebank.org';

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setHtmlBody(emailBody);
            message.setToAddresses(new List<String>{service.ContactEmail__c});
            message.setOrgWideEmailAddressId(clientServiceEmailAddress.Id);
            message.setSubject('Your NW Furniture Bank delivery has been scheduled');
            if (service.ContactEmail__c != null) emailMessages.add(message);

            if (System.Test.isRunningTest()) continue;

            System.enqueueJob(
                    new SendSMSQueueable(
                            service.ServiceCityLocation__c,
                            service.ContactMobilePhone__c,
                            smsMessage
                    )
            );
        }

        if (emailMessages.isEmpty()) return;
        Messaging.sendEmail(emailMessages);
    }

    private void sendScheduledPickupMessage() {
        List<Task> pendingTasks = new List<Task>();

        OrgWideEmailAddress infoNWFB = OrgWideEmailAddressSelector.getInstance().getOrgWideEmailAddress(
                'info@nwfurniturebank.org'
        );

        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

        Set<Id> serviceIds = new Set<Id>();
        for (Service__c service : (List<Service__c>) records) {
            Service__c oldService = (Service__c) oldRecordsById.get(service.Id);

            if (service.RecordTypeName__c != 'DonationPickup') continue;
            if (service.Trip__c == null) continue;
            if (oldService.Status__c == 'Pick Up' && service.Status__c == 'Pick Up') continue;
            if (service.Status__c != 'Pick Up') continue;

            serviceIds.add(service.Id);
        }

        Map<String, List<SObject>> serviceItemsByServiceId = Utils.listToMapLists(
                'Service__c',
                new ServiceItemSelector().getServiceItemsByServiceIds(serviceIds)
        );

        for (Service__c service : (List<Service__c>) records) {
            Service__c oldService = (Service__c) oldRecordsById.get(service.Id);

            if (service.RecordTypeName__c != 'DonationPickup') continue;
            if (service.Trip__c == null) continue;
            if (oldService.Status__c == 'Pick Up' && service.Status__c == 'Pick Up') continue;
            if (service.Status__c != 'Pick Up') continue;

            List<ServiceItem__c> items = serviceItemsByServiceId.get(service.Id);

            String itemsNames = '';
            if (items != null && !items.isEmpty()) {
                for (ServiceItem__c item : items) {
                    itemsNames += item.Quantity__c + 'x ' + item.Product__r.Name +
                            '<br>';
                }
            }

            String tripDate = service.TripDate__c.month() + '/' + service.TripDate__c.day() + '/' + service.TripDate__c.year();
            String timeframeRanged = service.TripTimeFrame__c == 'Morning' ? '9am-2pm' : '2pm-5pm';
            String aptNumber = service.Apt_Unit_Number__c != null ?  service.Apt_Unit_Number__c + ', ' : '';

            String smsMessage = 'Hello ' + service.ContactName__c + ',' +
                    '<br>' +
                    '<br>' +
                    'Your Pick-up is scheduled for <b>' + tripDate + '</b> between ' + timeframeRanged + '.' +
                    '<br>' +
                    'The <b>$' + service.Pickup_Fee__c + ' pick-up service</b> fee will be processed upon completion of your donation. ' +
                    '<br>' +
                    '<b>Pick-up Address:</b> ' + service.Address__c + ', ' + aptNumber + service.City__c +
                    '<br>' +
                    '<br>' +
                    '<b>Items:</b>' +
                    '<br>' +
                    itemsNames;

            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setHtmlBody(smsMessage);
            message.setToAddresses(new List<String>{service.ContactEmail__c});
            message.setOrgWideEmailAddressId(infoNWFB.Id);
            message.setSubject('Your NW Furniture Bank pick-up has been scheduled');
            if (service.ContactEmail__c != null) emailMessages.add(message);

            pendingTasks.add(
                    new Task(
                            Subject = 'Donation Pickup ' + service.Name + ' Confirmed',
                            WhatId = service.Id,
                            WhoId = service.Contact__c,
                            Priority = 'Normal',
                            Status = 'Completed',
                            ActivityDate = Date.today(),
                            Description = smsMessage
                    )
            );

            smsMessage = smsMessage.replaceAll('<b>', '');
            smsMessage = smsMessage.replaceAll('</b>', '');

            if (System.Test.isRunningTest()) continue;

            System.enqueueJob(
                    new SendSMSQueueable(
                            service.ServiceCityLocation__c,
                            service.ContactMobilePhone__c,
                            smsMessage.replaceAll('<br>', '\n')
                    )
            );
        }

        if (emailMessages != null && !emailMessages.isEmpty()) {
            Messaging.sendEmail(emailMessages);
        }

        if (pendingTasks == null || pendingTasks.isEmpty()) return;
        Database.insert(pendingTasks);

    }

    @TestVisible
    private void setServiceName() {
        Set<Id> contactIds = new Set<Id>();
        Set<Id> agencyIds = new Set<Id>();

        for (Service__c service : (List<Service__c>) this.records) {
            contactIds.add(service.Contact__c);
            agencyIds.add(service.Agency__c);
        }

        Map<Id, SObject> contactsById = Utils.listToMap(
                'Id',
                ContactSelector.getInstance().getContactsByIds(contactIds)
        );

        Map<Id, SObject> agenciesById = Utils.listToMap(
                'Id',
                AccountSelector.getInstance().getById(agencyIds)
        );

        if (contactsById == null || contactsById.isEmpty()) return;

        Id generalPickupRecordTypeId = Utils.getRecordTypeId(Service__c.SObjectType, 'General Pickup');

        for (Service__c service : (List<Service__c>) this.records) {

            Contact currentContact = (Contact) contactsById.get(service.Contact__c);
            if (currentContact == null) continue;

            service.Name = currentContact.FirstName + ' ' + System.now().format('MM/dd/yyyy', 'America/Los_Angeles');

            if (service.RecordTypeId == generalPickupRecordTypeId && service.SubType__c == 'Corporate') {
                Account currentAgency = (Account) agenciesById.get(service.Agency__c);
                if (currentAgency == null) continue;

                if (service.CreatedDate != null) {
                    service.Name = currentAgency.Name + ' ' + service.CreatedDate.format('MM/dd/yyyy', 'America/Los_Angeles');
                    continue;
                }

                service.Name = currentAgency.Name + ' ' + System.now().format('MM/dd/yyyy', 'America/Los_Angeles');
                continue;
            }

            if (service.Date__c != null) {
                Datetime serviceDateTime = Datetime.newInstance(
                        service.Date__c.year(),
                        service.Date__c.month(),
                        service.Date__c.day(),
                        0,
                        0,
                        0
                );
                service.Name = currentContact.FirstName + ' ' + serviceDateTime.format('MM/dd/yyyy');
                continue;
            }

            if (service.CreatedDate != null) {
                service.Name = currentContact.FirstName + ' ' + service.CreatedDate.format('MM/dd/yyyy', 'America/Los_Angeles');
            }
        }
    }

    // private void setTotalTaxableAmount() {
    //     Set<Id> serviceIds = new Set<Id>();

    //     for (Service__c service : (List<Service__c>) this.records) {
    //         serviceIds.add(service.Id);
    //     }

    //     Map<String, List<SObject>> serviceItemsByServices = Utils.listToMapLists(
    //             'Service__c',
    //             new ServiceItemSelector().getTaxableServiceItemsById(serviceIds)
    //     );

    //     for (Service__c service : (List<Service__c>) this.records) {
    //         List<ServiceItem__c> serviceItemsByService = serviceItemsByServices.get(service.Id);

    //         if (serviceItemsByService == null || serviceItemsByService.isEmpty()) continue;

    //         for (ServiceItem__c serviceItem : serviceItemsByService) {
    //             if (serviceItem.Total_Fee__c != null) service.TotalTaxableAmount__c = serviceItem.Total_Fee__c;
    //         }
    //     }
    // }

    private void countAmountOfRequestInTheLastYear() {
        Set<Id> contactIds = new Set<Id>();

        for (Service__c service : (List<Service__c>) this.records) {
            contactIds.add(service.Contact__c);
        }

        List<Service__c> services = ServiceSelector.getInstance().getServiceByContactIdAndDate(contactIds);

        List<Contact> contactToUpdateList = getbranchStateToBranchAmountMap(services, contactIds);

        saveRecords(contactToUpdateList);
    }

    private List<Contact> getbranchStateToBranchAmountMap(List<Service__c> services, Set<Id> contactIds) {
        List<Contact> contactToUpdateList = new List<Contact>();

        for (Id id : contactIds) {
            Map<String, Integer> contactIdToRequestAmountMap = new Map<String, Integer>();

            for (Service__c service : services) {
                Integer serviceAmount = (Integer) service.RequestAmount__c;
                String contactId = service.Contact__c;
                contactIdToRequestAmountMap.put(contactId, serviceAmount);
            }

            contactToUpdateList.add(
                    new Contact(
                            Id = id,
                            RequestsAssignedIntheLastYear__c = contactIdToRequestAmountMap.get(id)
                    )
            );
        }

        return contactToUpdateList;
    }

    private void sendEmailBasedOnStatus() {
        Set<Id> serviceIds = new Set<Id>();

        for (Service__c service : (List<Service__c>) this.records) {
            serviceIds.add(service.Id);
        }

        List<String> emailTemplateNames = new List<String>{
                'RequestScheduledTemplate',
                'CaseWorkerRequestScheduledTemplate',
                'NoResponseFromTemplate'
        };

        Map<String, EmailTemplate> emailTemplatesByNameMap = EmailTemplateSelector.getInstance().getEmailTemplatesByDeveloperNames(emailTemplateNames);

        Map<Id, Service__c> serviceMap = new Map<Id, Service__c>(
                ServiceSelector.getInstance().getServiceByIds(serviceIds)
        );

        OrgWideEmailAddress tacomaAddressToOrgWideEmail = OrgWideEmailAddressSelector.getInstance().getOrgWideEmailAddress(
                'clientservices@nwfurniturebank.org'
        );
        OrgWideEmailAddress vancouverAddressToOrgWideEmail = OrgWideEmailAddressSelector.getInstance().getOrgWideEmailAddress(
                'vaninfo@nwfurniturebank.org'
        );

        List<Task> taskListToCreate = new List<Task>();

        for (Service__c service : (List<Service__c>) this.records) {
            Service__c currentService = serviceMap.get(service.Id);

            OrgWideEmailAddress currentOrgWideEmailAddress = currentService.Location__r.City__c == 'Tacoma'
                    ? tacomaAddressToOrgWideEmail
                    : vancouverAddressToOrgWideEmail;


            if (service.Status__c == 'Scheduled') {
                taskListToCreate.add(
                        sendEmail(
                                emailTemplatesByNameMap.get('CaseworkerAppointmentScheduledEmail'),
                                serviceMap.get(service.Id),
                                currentOrgWideEmailAddress.Id
                        )
                );

                taskListToCreate.add(
                        sendEmail(
                                emailTemplatesByNameMap.get('CaseworkerAppointmentScheduledEmail'),
                                serviceMap.get(service.Id),
                                currentOrgWideEmailAddress.Id
                        )
                );
                taskListToCreate.add(sendSMSRequestScheduled(serviceMap.get(service.Id)));

            } else if (service.Status__c == 'Expiring') {
                taskListToCreate.add(
                        sendEmail(
                                emailTemplatesByNameMap.get('RequestNotFoundEmailTemplate'),
                                serviceMap.get(service.Id),
                                currentOrgWideEmailAddress.Id
                        )
                );
            }
        }

        saveRecords(taskListToCreate);
    }

    private Task sendEmail(EmailTemplate emailTemplatesByNameMap, Service__c service, Id orgWideEmailAddressId) {
        List<String> toEmailAddressList = new List<String>{
                service.Contact__r.Email
        };
        Task task;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        System.debug(emailTemplatesByNameMap);
        if (emailTemplatesByNameMap == null) return null;
        mail.setTemplateId(emailTemplatesByNameMap.Id);
        mail.setToAddresses(toEmailAddressList);
        mail.setTargetObjectId(service.Contact__c);
        mail.setSaveAsActivity(false);
        mail.setOrgWideEmailAddressId(orgWideEmailAddressId);

        List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>{
                mail
        };

        try {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailMessageList);
            task = registerMessaging(results, service, null);

        } catch (Exception e) {
            System.debug(e.getMessage());
            task = registerMessaging(null, service, e);
        }

        return task;
    }

    private Task sendSMSRequestScheduled(Service__c service) {
        String body = 'Your service has been scheduled for ' + service.Date__c + ' at NW Furniture Bank located at ' + service.Location__r.Address__c + '.';
        Task task;

        try {
            if (!Test.isRunningTest()) {
//                System.enqueueJob(new SendSMSQueueable(service.Contact__r.MobilePhone, body));

            }

            task = registerMessaging(null, service, null);
        } catch (Exception e) {

            System.debug(e.getMessage());
            task = registerMessaging(null, service, e);
        }
        return task;
    }

    private Task registerMessaging(List<Messaging.SendEmailResult> results, Service__c service, Exception e) {
        Task task;
        Id recordType;
        String taskSubtype;
        String type;
        String description;

        if (results == null) {
            recordType = Schema.SObjectType.Task.getRecordTypeInfosByName().get('SMS').getRecordTypeId();
            taskSubtype = 'Task';
            type = 'SMS';
            description = 'An Confirmation SMS has been sent';
//            task = createTask(service, e, recordType, taskSubtype, type, description);

        } else {
            recordType = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sent Email').getRecordTypeId();
            taskSubtype = 'Email';
            type = 'Email';
            description = 'An Confirmation Email has been sent';
//            task = createTask(service, e, recordType, taskSubtype, type, description);
        }

        return task;
    }

//    private Task createTask(Service__c service, Exception e, Id recordType, String taskSubtype, String type, String description) {
//
//        if (e != null) {
//            description = 'Confirmation message bounced.';
//
//        }
//
//        Task task = new Task(
//                Priority = 'Normal',
//                Subject = 'Will Call',
//                Status = 'Not Started',
//                RecordTypeId = recordType,
//                TaskSubtype = taskSubtype,
//                Type = type,
//                WhoId = service.Contact__c,
//                OwnerId = service.OwnerId,
//                Description = description
//        );
//
//        return task;
//    }

    private void saveRecords(List<SObject> sobjectListToInsert) {
        try {
            Database.upsert(sobjectListToInsert, false);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    private void blockRequestStatusChange() {
        Map<Id, Service__c> oldServices = (Map<Id, Service__c>) this.oldRecordsById;
        Set<Id> serviceIds = new Set<Id>();

        for (Service__c service : (List<Service__c>) this.records) {
            serviceIds.add(service.Id);
        }

        List<Service__c> services = ServiceSelector.getInstance().getServiceByIds(serviceIds);

        for (Service__c service : services) {
            Service__c oldService = oldServices.get(service.Id);
            List<ServiceItem__c> serviceItems = service.ServiceItems__r;

            if (serviceItems.isEmpty() && (oldService.Status__c == 'Processing' && service.Status__c != 'Processing')) {
                String errorMessage = 'You can not change Status from "Processing" if your service do not have any service items';
                service.addError(errorMessage);
                return;
            }
        }
    }

    private void setNewStatus() {
        Map<Id, Service__c> oldServices = (Map<Id, Service__c>) this.oldRecordsById;

        for (Service__c service : (List<Service__c>) this.records) {
            if (service.Trip__c != null && service.Trip__c != oldServices.get(service.Id).Trip__c) {
                if (service.RecordTypeName__c == 'ClientRequest') {
                    service.Status__c = 'Shopping';
                } else if (service.RecordTypeName__c == 'GeneralPickup' || service.RecordTypeName__c == 'DonationPickup') {
                    service.Status__c = 'Pick Up';
                } else {
                    service.Status__c = 'Delivery';
                }
            }
        }
    }

    private void setDefaultLocationBasedOnUser() {
        Id currentUserId = UserInfo.getUserId();

        List<User_Location__c> userLocation = [
                SELECT Id, Location__c
                FROM User_Location__c
                WHERE User__c = :currentUserId AND main__c = TRUE
                ORDER BY CreatedDate DESC
                LIMIT 1
        ];

        if (userLocation == null || userLocation.isEmpty()) return;

        for (Service__c service : (List<Service__c>) this.records) {
            if (service.Location__c != null) continue;
            service.Location__c = userLocation[0].Location__c;
        }
    }

    @TestVisible
    private void setAgreementText() {
        String agreementText = MetadataSelector.getAgreementText();
        for (Service__c service : (List<Service__c>) this.records) {
            service.AgreementText__c = agreementText;
        }
    }

//    public void getDuplicatedActiveRequests(List<Service__c> serviceList) {
//
//        Map<Id, List<SObject>> masterRecordIdToDuplRecordsMap = new Map<Id, List<SObject>>();
//
//        try {
//            List<Datacloud.FindDuplicatesResult> results = Datacloud.FindDuplicates.findDuplicates(serviceList);
//            if (!results.isEmpty()) {
//
//                for (Integer index = 0; index < results.size(); index++) {
//                    for (Datacloud.DuplicateResult dupeResult : results.get(index).getDuplicateResults()) {
//                        for (Datacloud.MatchResult matchResult : dupeResult.getMatchResults()) {
//                            if (!matchResult.getMatchRecords().isEmpty()) {
//                                //Record in the recordsList list has the same order as in results list
//                                Id masterRecordId = serviceList[index].Id;
//
//                                if (!masterRecordIdToDuplRecordsMap.containsKey(masterRecordId)) {
//                                    masterRecordIdToDuplRecordsMap.put(masterRecordId, new List<SObject>());
//                                }
//
//                                for (Datacloud.MatchRecord duplicate : matchResult.getMatchRecords()) {
//
//                                    masterRecordIdToDuplRecordsMap.get(masterRecordId).add(duplicate.getRecord());
//                                }
//                                System.debug(masterRecordId + ' has duplicates : ' + masterRecordIdToDuplRecordsMap.get(masterRecordId));
//                            }
//                        }
//                    }
//                }
//            }
//
//            deleteDuplicateRecords(masterRecordIdToDuplRecordsMap.values());
//
//        } catch (Exception e) {
//            System.debug('exception thrown : ' + e.getMessage());
//        }
//    }

    public void deleteDuplicateRecords(List<List<SObject>> listOfRecordListToDelete) {
        List<SObject> recordListToDelete = new List<SObject>();

        for (List<SObject> recordList : listOfRecordListToDelete) {
            for (SObject record : recordList) {
                recordListToDelete.add(record);
            }
        }

        if (!recordListToDelete.isEmpty() && recordListToDelete != null) {
            Database.delete(recordListToDelete);
        }
    }


    private void setFeeAmount() {
        Set<Id> serviceIds = new Set<Id>();

        for (Service__c service : (List<Service__c>) this.records) {
            serviceIds.add(service.Id);
        }

        Map<String, ServiceFeesSettings__mdt> serviceFeesSettingsByDevName = new Map<String, ServiceFeesSettings__mdt>();
        List<ServiceFeesSettings__mdt> serviceFeesSettings = CustomMetadataSelector.getInstance().getMdtByStatus();

        for (ServiceFeesSettings__mdt serviceFeeSetting : serviceFeesSettings) {
            serviceFeesSettingsByDevName.put(serviceFeeSetting.DeveloperName, serviceFeeSetting);
        }

        Map<String, List<ServiceItem__c>> serviceItemsByService = Utils.listToMapLists(
                'Service__c',
                new ServiceItemSelector().getTaxableServiceItemsById(serviceIds)
        );

        Map<Id, SObject> serviceById = Utils.listToMap(
                'Id',
                ServiceSelector.getInstance().getServiceByIds(serviceIds)
        );

        if (serviceById == null) return;

        for (Service__c service : (List<Service__c>) this.records) {

            if (service.OverrideFeeCalculation__c) continue;
            Service__c currentService = (Service__c) serviceById.get(service.Id);

            if (currentService == null) continue;
            if (serviceFeesSettingsByDevName.isEmpty()) continue;

            if (currentService.RecordType.DeveloperName == 'ClientRequest') {
                service.Processing_Fee__c = serviceFeesSettingsByDevName.get('ProcessingFee').DeliveryFeeAmount__c;

                if (service.SubType__c == 'Delivery') {
                    service.Delivery_Fee__c = serviceFeesSettingsByDevName.get('DeliveryFee').FeeAmount__c;
                }

            } else if (currentService.RecordType.DeveloperName == 'DonationPickup') {
                //if (serviceItemsByService.get(service.Id) == null || serviceItemsByService.get(service.Id).isEmpty()) continue;
                service.Pickup_Fee__c = serviceFeesSettingsByDevName.get('PickupFee').FeeAmount__c;
            }
        }
    }

    private void setTaxPercentage() {
        Map<Id, Service__c> servicesByLocation = new Map<Id, Service__c>();

        for (Service__c service : (List<Service__c>) this.records) {
            servicesByLocation.put(service.Location__c, service);
        }

        Map<Id, Location__c> relatedLocation = LocationSelector.getInstance().getLocationByIds(servicesByLocation.keySet());

        for (Service__c service : (List<Service__c>) this.records) {

            if (relatedLocation.get(service.Location__c) == null || relatedLocation.isEmpty()) {
                continue;
            }

            service.TaxPercentage__c = relatedLocation.get(service.Location__c)?.TaxRate__c;
        }
    }

    private void calculateTotalTaxAmount() {
        Set<Id> serviceIds = new Set<Id>();
        Decimal taxTotal;
        for (Service__c service : (List<Service__c>) this.records) {
            serviceIds.add(service.Id);
        }

        Map<String, List<SObject>> serviceItemsByServiceId = Utils.listToMapLists(
                'Service__c',
                new ServiceItemSelector().getTaxableServiceItemsById(serviceIds)
        );

        for (Service__c service : (List<Service__c>) this.records) {
            if (service.OverrideFeeCalculation__c) continue;
            taxTotal = 0;
            List<ServiceItem__c> serviceItems = serviceItemsByServiceId.get(service.Id);

            if (serviceItems == null || serviceItems.isEmpty()) continue;

            for (ServiceItem__c serviceItem : serviceItems) {
                if (serviceItem.TaxableItem__c) taxTotal = taxTotal + serviceItem.Total_Fee__c;
            }

            service.TotalTaxableAmount__c = taxTotal * (service.TaxPercentage__c / 100);
        }
    }

    public static Boolean isValidEmail(String emailAddress) {
        String emailRegex = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$';
        return Pattern.matches(emailRegex, emailAddress);
    }

    public void callSendInvoiceForCaseworkerAPContact() {
        Set<Id> serviceIds = new Set<Id>();

        for (Service__c service : (List<Service__c>) this.records) {
            if (!service.InvoiceProcessingFee__c) continue;
            serviceIds.add(service.Id);
        }

        if (serviceIds == null || serviceIds.isEmpty()) return;

        List<Service__c> services = new ServiceSelector().getClientRequestServicesById(serviceIds);

        if (services == null || services.isEmpty()) return;

        for (Service__c service : services) {
            callGenerateInvoiceAndSendPDF(
                    service.Id,
                    true,
                    false,
                    true
            );
        }
    }

    @AuraEnabled
    public static String callGenerateInvoiceAndSendPDF(Id serviceId, Boolean sendToCaseWorker, Boolean sendToContact, Boolean sendToAPContacts) {
        Service__c service = ServiceSelector.getInstance().getServiceByIds(new Set<Id>{
                serviceId
        })[0];
        List<String> emailsAddresses = new List<String>();
        Boolean emailsValidated = true;

        fetchEmailsAddresses(service, sendToCaseWorker, sendToContact, sendToAPContacts, emailsAddresses);

        if (!emailsAddresses.isEmpty()) {
            for (String address : emailsAddresses) {
                if (!isValidEmail(address)) {
                    emailsValidated = false;
                    break;
                }
            }
        }


        if (!emailsValidated) {
            return 'The invoices was not generated. The entered email address is invalid';
        }

        Decimal invoiceVersion = service.InvoiceVersion__c == null
                ? 0
                : service.InvoiceVersion__c + 1;

        service.InvoiceVersion__c = invoiceVersion;

        update new Service__c(
                Id = serviceId,
                InvoiceCreated__c = System.now(),
                InvoiceVersion__c = invoiceVersion
        );

        generateInvoiceAndSendPDF(service.Id, emailsAddresses);
        return 'SentEmails';
    }

    @Future(Callout=true)
    public static void generateInvoiceAndSendPDF(String serviceId, List<String> emailsAddresses) {
        Service__c service = ServiceSelector.getInstance().getServiceByIds(new Set<Id>{
                serviceId
        })[0];

        PageReference PDF = Page.InvoicePDF;
        PDF.getParameters().put('Id', serviceId);
        PDF.setRedirect(true);

        Blob b;
        ContentVersion pdfFile = new ContentVersion();

        if (!Test.isRunningTest()) {
            b = PDF.getContent();
            pdfFile = Utils.createContentVersion(
                    'Invoice: ' +
                            service.InvoiceNumberVersion__c +
                            '.pdf',
                    b,
                    serviceId);
        }

        if (emailsAddresses.isEmpty()) return;

        EmailTemplate invoiceTemplate = new EmailTemplateSelector().getEmailTemplateByName('InvoiceTemplate');
        EmailTemplate invoiceTemplateVersion1 = new EmailTemplateSelector().getEmailTemplateByName('Invoice Template Invoice Version 1');
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        if (service.InvoiceVersion__c != 1) {
            mail.setTemplateId(invoiceTemplate.Id);
        } else {
            mail.setTemplateId(invoiceTemplateVersion1.Id);
        }

        OrgWideEmailAddress clientServicesOrgWideAddress = new OrgWideEmailAddressSelector().getOrgWideEmailAddress(
                'clientservices@nwfurniturebank.org'
        );
        mail.setOrgWideEmailAddressId(clientServicesOrgWideAddress.Id);
        mail.setToAddresses(emailsAddresses);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setTargetObjectId(service.Caseworker__c);
        mail.setWhatId(service.Id);
        mail.setSaveAsActivity(false);

        // Create attachment
        Messaging.EmailFileAttachment mailAttachment = new Messaging.EmailFileAttachment();
        mailAttachment.setBody(b);
        mailAttachment.setContentType('application/pdf');
        mailAttachment.setFileName(pdfFile.Title);
        mailAttachment.setInline(false);

        if (!Test.isRunningTest()) {
            mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{
                    mailAttachment
            });
        }

        Messaging.sendEmail(new List<Messaging.Email>{
                mail
        });

        Task emailTask = new Task(
                Subject = 'Email:' + mail.getSubject(),
                ContactAttempt__c = service.InvoiceVersion__c != 1,
                Status = 'Completed',
                WhatId = service.Id,
                WhoId = service.Caseworker__c,
                Type = 'Email',
                TaskSubtype = 'Email'
        );
        insert emailTask;


//        update new Service__c(Id = service.Id, InvoiceCreated__c = System.now(), InvoiceVersion__c = invoiceVersion);
    }

    public static void fetchEmailsAddresses(Service__c service, Boolean caseWorkerEmail, Boolean contactEmail, Boolean apEmails, List<String> addresses) {
        if (caseWorkerEmail) {
            if (service.Caseworker__r.npe01__Preferred_Email__c != null) {
                if (service.Caseworker__r.npe01__Preferred_Email__c == 'Personal') {
                    addresses.add(service.Caseworker__r.npe01__HomeEmail__c);
                } else if (service.Caseworker__r.npe01__Preferred_Email__c == 'Work') {
                    addresses.add(service.Caseworker__r.npe01__WorkEmail__c);
                } else if (service.Caseworker__r.npe01__Preferred_Email__c == 'Alternate') {
                    addresses.add(service.Caseworker__r.npe01__AlternateEmail__c);
                }
            } else {
                if (service.Caseworker__r.npe01__HomeEmail__c != null) {
                    addresses.add(service.Caseworker__r.npe01__HomeEmail__c);
                }
                if (service.Caseworker__r.npe01__WorkEmail__c != null) {
                    addresses.add(service.Caseworker__r.npe01__WorkEmail__c);
                }
                if (service.Caseworker__r.npe01__AlternateEmail__c != null) {
                    addresses.add(service.Caseworker__r.npe01__AlternateEmail__c);
                }
            }
        }

        if (contactEmail) {
            if (service.Contact__r.npe01__Preferred_Email__c != null) {
                if (service.Contact__r.npe01__Preferred_Email__c == 'Personal') {
                    addresses.add(service.Contact__r.npe01__HomeEmail__c);
                } else if (service.Contact__r.npe01__Preferred_Email__c == 'Work') {
                    addresses.add(service.Contact__r.npe01__WorkEmail__c);
                } else if (service.Contact__r.npe01__Preferred_Email__c == 'Alternate') {
                    addresses.add(service.Contact__r.npe01__AlternateEmail__c);
                }
            } else {
                if (service.Contact__r.npe01__HomeEmail__c != null) {
                    addresses.add(service.Contact__r.npe01__HomeEmail__c);
                }
                if (service.Contact__r.npe01__WorkEmail__c != null) {
                    addresses.add(service.Contact__r.npe01__WorkEmail__c);
                }
                if (service.Contact__r.npe01__AlternateEmail__c != null) {
                    addresses.add(service.Contact__r.npe01__AlternateEmail__c);
                }
            }
        }

        if (apEmails && service.Caseworker__r.AP_Contact_Email__c != null) {
            addresses.add(service.Caseworker__r.AP_Contact_Email__c);
        }
    }

    public void adjustTruckNotes() {
        for (Service__c service : (List<Service__c>) records) {
            if (service.Id != null) {
                Service__c oldService = (Service__c) oldRecordsById.get(service.Id);

                if (service.TruckNotes__c == oldService.TruckNotes__c) continue;
                if (service.TruckNotes__c == null) continue;

                String clearedNotes = service.TruckNotes__c.replaceAll('<div style="color: red;"><b>', '');
                clearedNotes = service.TruckNotes__c.replaceAll('</b></div>', '');

                service.TruckNotes__c = '<div style="color: red;"><b>' + service.TruckNotes__c + '</b></div>';
                continue;
            }

            if (service.TruckNotes__c != null)  {
                service.TruckNotes__c = '<div style="color: red;"><b>' + service.TruckNotes__c + '</b></div>';
            }
        }
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new ServiceDao(objects, oldObjectsById);
        }
    }
}