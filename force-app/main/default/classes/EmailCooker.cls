/**
 * Created by Gustavo on 15/05/24.
 */

public without sharing class EmailCooker {

    private final List<Messaging.SingleEmailMessage> emails;
    private final Map<String, List<Messaging.SingleEmailMessage>> emailsByKey;

    public EmailCooker() {
        this.emails = new List<Messaging.SingleEmailMessage>();
        this.emailsByKey = new Map<String, List<Messaging.SingleEmailMessage>>();
    }

    public List<Messaging.SingleEmailMessage> getEmails() {
        return this.emails;
    }

    public Map<String, List<Messaging.SingleEmailMessage>> getEmailsMap() {
        return this.emailsByKey;
    }

    public EmailCooker addEmail(Id orgWideEmailAddressId, String toAddress, Id emailTemplateId,
            Id targetObjectId, Id whatId, List<Messaging.EmailFileAttachment> attachments, String key) {
        this.addEmail(
                orgWideEmailAddressId,
                new List<String>{toAddress},
                emailTemplateId,
                targetObjectId,
                whatId,
                attachments,
                key
        );
        return this;
    }

    public EmailCooker addEmail(Id orgWideEmailAddressId, String toAddress, Id emailTemplateId,
            Id targetObjectId, Id whatId, List<Messaging.EmailFileAttachment> attachments) {
        this.addEmail(
                orgWideEmailAddressId,
                new List<String>{toAddress},
                emailTemplateId,
                targetObjectId,
                whatId,
                attachments,
                null
        );
        return this;
    }

    public EmailCooker addEmail(Id orgWideEmailAddressId, List<String> toAddresses, Id emailTemplateId,
            Id targetObjectId, Id whatId, List<Messaging.EmailFileAttachment> attachments, String key) {
        Messaging.SingleEmailMessage emailMessage = new Messaging.SingleEmailMessage();
        emailMessage.setOrgWideEmailAddressId(orgWideEmailAddressId);
        emailMessage.setToAddresses(toAddresses);
        emailMessage.setTemplateId(emailTemplateId);
        emailMessage.setTargetObjectId(targetObjectId);
        emailMessage.setTreatTargetObjectAsRecipient(false); // we may want to add this as a parameter in the future

        if (targetObjectId.getSobjectType() == User.SObjectType) {
            emailMessage.setSaveAsActivity(false);
        } else {
            if (whatId != null) emailMessage.setWhatId(whatId);
            emailMessage.setSaveAsActivity(true);
        }

        if (attachments != null && !attachments.isEmpty()) emailMessage.setFileAttachments(attachments);

        if (String.isNotEmpty(key)) {
            List<Messaging.SingleEmailMessage> messages = this.emailsByKey.get(key);
            if (messages == null) messages = new List<Messaging.SingleEmailMessage>{emailMessage};
            else messages.add(emailMessage);
            this.emailsByKey.put(key, messages);
        }

        this.emails.add(emailMessage);
        return this;
    }

    public EmailCooker cook() {
        Savepoint sp = Database.setSavepoint();
        Messaging.sendEmail(this.emails);
        Database.rollback(sp);
        return this;
    }

    public void send() {
        Messaging.sendEmail(this.emails);
    }
}