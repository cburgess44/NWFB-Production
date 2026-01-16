/**
 * Created by Gustavo on 05/01/24.
 */

@IsTest
private class ServiceItemDaoTest {
    @TestSetup
    private static void setup() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;

        Product__c product = new Product__c(
            Name = 'Test',
            Product_Code__c = 'Test1',
            Estimated_Value__c = 10,
            Taxable__c = true,
            Limit__c = 'Single',
            Product_Fee__c = 10,
            Pick_up_Fee__c = 10
        );
        insert product;

        Service__c service = new Service__c(
                Contact__c = contact.Id
        );
        insert service;


    }

    @IsTest
    private static void setFees() {
        TriggerManagement.disableTrigger('ServiceTrigger');

        Product__c product = [SELECT Id FROM Product__c LIMIT 1];
        Service__c service = [SELECT Id FROM Service__c LIMIT 1];

        service.RecordTypeId = Utils.getRecordTypeId(Service__c.SObjectType, 'Client Request');
        service.SubType__c = 'Delivery';
        update service;

        ServiceItem__c serviceItem = new ServiceItem__c(
                Product__c = product.Id,
                Service__c = service.Id,
                TotalItemPrice__c = 0
        );
        insert serviceItem;
        ServiceItemDao.getInstance().setFees();

        ServiceItem__c updatedServiceItem = [SELECT Id, TaxableItem__c, TotalItemPrice__c FROM ServiceItem__c LIMIT 1];

        System.assert(updatedServiceItem.TotalItemPrice__c > 0);
        System.assert(updatedServiceItem.TaxableItem__c == true);

        TriggerManagement.enableTrigger('ServiceTrigger');
    }
}