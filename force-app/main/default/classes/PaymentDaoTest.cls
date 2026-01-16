/**
 * Created by Gustavo on 05/01/24.
 */

@IsTest
private class PaymentDaoTest {

    @IsTest
    public static void sendRefundEmail() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
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
                PaymentType__c = 'Refund',
                Service__c = service.Id
        );
        insert payment;

        System.assertEquals(1, Limits.getEmailInvocations(), 'No emails should be sent');
    }
}