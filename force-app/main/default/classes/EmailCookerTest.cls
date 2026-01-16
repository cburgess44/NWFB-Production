/**
 * Created by Gustavo on 12/06/24.
 */

@IsTest
private class EmailCookerTest {
    @IsTest
    static void addEmailWithKey() {
        EmailCooker emailCooker = new EmailCooker();
        OrgWideEmailAddress orgWideEmailAddressSelector = new OrgWideEmailAddressSelector().getOrgWideEmailAddress(
                'clientservices@nwfurniturebank.org'
        );

        EmailTemplate emailTemplate = new EmailTemplateSelector().getEmailTemplateByName(
               'Client Request Expired'
        );

        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test',
                Email = 'test+test@gmail.com'
        );
        insert contact;

        Service__c service = new Service__c(
                Contact__c = contact.Id,
                Status__c = 'Processing'
        );
        insert service;

        emailCooker.addEmail(
                orgWideEmailAddressSelector.Id,
                contact.Email,
                emailTemplate.Id,
                contact.Id,
                service.Id,
                null,
                'test'
        );

        List<Messaging.SingleEmailMessage> emails = emailCooker.getEmails();
        Map<String, List<Messaging.SingleEmailMessage>> emailsMap = emailCooker.getEmailsMap();
        emailCooker.cook();

        System.assert(emails.size() == 1);
    }
}