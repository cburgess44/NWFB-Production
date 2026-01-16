/**
 * Created by calebeaires on 18/03/22.
 */

@IsTest
private class SObjectCRUDControllerTest {
    @IsTest
    static void testItAll() {
        List<Account> accounts = (List<Account>) SObjectCRUDController.saveSObjects(
                new List<Account>{
                        new Account(
                                Name = 'Test',
                                ShippingCountry = 'Germany'
                        )
                }
        );

        System.assert(accounts.size() == 1);

        List<Account> accountsFetched = (List<Account>) SObjectCRUDController.listSObjects(
                'Account',
                new List<String>{
                        'Name'
                },
                'AND Id = \'' + accounts[0].Id + '\''
        );

        System.assertEquals(accounts[0].Name, accountsFetched[0].Name);

        SObjectCRUDController.deleteSObjects(accounts);


        System.assert([SELECT Id FROM Account].size() == 0);

    }

    @IsTest
    static void deleteSObjectByFilter() {
        Account account = new Account(
                Name = 'Test',
                ShippingCountry = 'Germany'
        );
        insert account;

        SObjectCRUDController.deleteSObjectsByFilter('Account', 'AND Name = \'Test\'');
        System.assert([SELECT Id FROM Account WHERE Name = 'Test'].isEmpty());
    }

    @IsTest
    static void getPicklist() {
        List<PicklistEnum.Entry> picklistValues = SObjectCRUDController.getPicklist('Service__c', 'Status__c');
        System.assert(picklistValues != null && !picklistValues.isEmpty());
    }

    @IsTest
    static void getCustomSettings() {
        NWFBSettings__c nwfbSettings = SObjectCRUDController.getCustomSettings();
        System.assert(nwfbSettings != null);
    }
}