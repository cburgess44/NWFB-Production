/**
 * Created by Gustavo on 03/01/24.
 */

@IsTest
public with sharing class InvoiceDaoTest {

    @TestSetup
    public static void setup() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;

        Service__c service = new Service__c(
                Contact__c = contact.Id,
                Status__c = 'Processing'
        );
        insert service;
    }


    @IsTest
    public static void setCreateInvoiceDate() {

        Service__c service = [SELECT Id FROM Service__c WHERE Contact__r.FirstName = 'Test'];

        Invoice__c invoice = new Invoice__c(
                DueDate__c = Date.newInstance(2024, 01, 01),
                Status__c = 'Submitted',
                Service__c = service.Id
        );
        insert invoice;

        Payment__c payment = new Payment__c(
                PaymentAmount__c = 10,
                PaymentMethod__c = 'DebitCard',
                PaymentType__c = 'Refund',
                Service__c = service.Id
        );
        insert payment;
        insert new InvoicePayment__c(Amount__c = 1, Invoice__c = invoice.Id, Payment__c = payment.Id);


        Service__c clearedServiceField = [SELECT Id, InvoiceCreated__c FROM Service__c WHERE Contact__r.FirstName = 'Test'];
        System.assert(clearedServiceField.InvoiceCreated__c != null);
        delete invoice;
        Service__c populatedServiceField = [SELECT Id, InvoiceCreated__c FROM Service__c WHERE Contact__r.FirstName = 'Test'];
        System.assert(populatedServiceField.InvoiceCreated__c == null);
    }

    @IsTest
    public static void setDueDate() {
        Service__c service = [SELECT Id FROM Service__c WHERE Contact__r.FirstName = 'Test'];

        Invoice__c invoice = new Invoice__c(
                DueDate__c = Date.newInstance(2024, 01, 01),
                Status__c = 'Draft',
                Service__c = service.Id
        );
        insert invoice;

        invoice.CreateDate__c = Date.today();
        update invoice;

        Invoice__c updatedInvoice = [
                SELECT
                        DueDate__c,
                        CreateDate__c
                FROM Invoice__c
                WHERE Id = :invoice.Id
        ];

        System.assert(updatedInvoice.DueDate__c == updatedInvoice.CreateDate__c.addDays(30));
    }

}