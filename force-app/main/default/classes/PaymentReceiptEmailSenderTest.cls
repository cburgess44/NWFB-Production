/**
 * Created by Gustavo on 12/06/24.
 */

@IsTest
private class PaymentReceiptEmailSenderTest {
    @IsTest
    static void testBehavior() {
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
        TriggerManagement.disableTrigger('ServiceTrigger');
        insert service;

        Payment__c payment = new Payment__c(
                PaymentAmount__c = 10,
                PaymentMethod__c = 'DebitCard',
                Payee_Type__c = 'Client',
                Service__c = service.Id
        );

        insert payment;
        PaymentReceiptEmailSender.send(new Set<Id>{payment.Id});
        System.assert(Limits.getEmailInvocations() == 1);
    }
}