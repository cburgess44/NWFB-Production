/**
 * Created by Gustavo on 10/01/24.
 */

@IsTest
private class RequestRelatedListControllerTest {
    @IsTest
    static void getRequestCurrentPage() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;

        Service__c service = new Service__c(
            Contact__c = contact.Id
        );
        insert service;

        System.assert(RequestRelatedListController.getRequestCurrentPage(service.Id, 1, 1) != null);
    }
}