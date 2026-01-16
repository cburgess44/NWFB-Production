@isTest
public class RelatedListControllerTest {
    @isTest
    static void fetchRecordsTest(){
        String param = '';

        Account acct = new Account(
            Name = 'Account Teste',
            Type = 'Agency'
        );
        insert acct;

        Contact ctct = new Contact(
            AccountId = acct.Id,
            LastName = 'Test'
        );
        insert ctct;

        
        
        param = acct.Id + '-';
        param += 'Contact-';
        param += 'AccountId-';
        param += 'LastName';

        Test.startTest();
        RelatedListController.RelatedListWrapper result = RelatedListController.fetchRecords(param);
        Test.stopTest();
        System.assertEquals(1, result.listRecords.size());

        
    }
}