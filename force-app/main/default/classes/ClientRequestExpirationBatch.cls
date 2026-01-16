global class ClientRequestExpirationBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

    global Database.QueryLocator start(Database.BatchableContext BC) {

        return Database.getQueryLocator([
            SELECT  Id,
                    Caseworker__c,
                    Caseworker__r.Email,
                    NumberOfScheduledAppointments__c,
                    Expiration_Date__c,
                    DeletionDate__c,
                    Status__c,
                    Location__r.City__c
            FROM Service__c
            WHERE RecordType.DeveloperName = 'ClientRequest'
        ]);
    }

    global void execute(Database.BatchableContext BC, List<Service__c> scope) {
        List<Service__c> expiredServices = new List<Service__c>();
        List<Service__c> serviceToDelete = new List<Service__c>();
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

        OrgWideEmailAddress tacomaEmailAddress = new OrgWideEmailAddressSelector().getOrgWideEmailAddress(
                'clientservices@nwfurniturebank.org'
        );

        OrgWideEmailAddress vancouverEmailAddress = new OrgWideEmailAddressSelector().getOrgWideEmailAddress(
                'vaninfo@nwfurniturebank.org'
        );

        EmailTemplate clientRequestExpiredEmailTemplate = EmailTemplateSelector.getInstance()
                .getEmailTemplateByDeveloperName('ClientRequestExpired');

        for (Service__c clientRequest : scope) {
            if (clientRequest.NumberOfScheduledAppointments__c > 0) continue;
            OrgWideEmailAddress currentlyEmailLocation = clientRequest.Location__r.City__c == 'Tacoma'
                    ? tacomaEmailAddress
                    : vancouverEmailAddress;

            if (Date.today() == clientRequest.Expiration_Date__c) {
                clientRequest.Status__c = 'Expired';
                expiredServices.add(clientRequest);
                Messaging.SingleEmailMessage mail = createEmail(
                        clientRequest,
                        clientRequestExpiredEmailTemplate.Id,
                        currentlyEmailLocation
                );
                if (mail != null) emailMessages.add(mail);
            }

            if (Date.today() == clientRequest.DeletionDate__c && clientRequest.Status__c == 'Expired') {
                serviceToDelete.add(clientRequest);
            }
        }

        if (!expiredServices.isEmpty()) {
            update expiredServices;
        }

        if (!emailMessages.isEmpty()) {
           Messaging.sendEmail(emailMessages);
        }

        if (!serviceToDelete.isEmpty()) {
            delete serviceToDelete;
        }
    }

    global void finish(Database.BatchableContext BC) {}

    private static Messaging.SingleEmailMessage createEmail(Service__c clientRequest, String templateId, OrgWideEmailAddress orgWideEmailAddress) {
        Messaging.SingleEmailMessage emailMessage = null;

        if (clientRequest.Caseworker__c != null) {
            emailMessage = new Messaging.SingleEmailMessage();
            emailMessage.setTemplateId(templateId);
            emailMessage.setTargetObjectId(clientRequest.Caseworker__c);
            emailMessage.setSaveAsActivity(false);
            emailMessage.setWhatId(clientRequest.Id);
            emailMessage.setOrgWideEmailAddressId(orgWideEmailAddress.Id);
            emailMessage.setToAddresses(new List<String>{clientRequest.Caseworker__r.Email});
        }
        return emailMessage;
    }
}