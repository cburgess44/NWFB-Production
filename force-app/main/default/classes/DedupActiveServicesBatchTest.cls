/**
 * Created by Eric Solari on 08/01/2024.
 */
@IsTest
public with sharing class DedupActiveServicesBatchTest {

    @IsTest
    public static void testBatch(){
        Account account = createAccount();
        insert account;
        Contact contact = createContact(account);
        insert contact;
        Service__c service = new Service__c(IsActive__c = true, Name ='test', State__c='WA', Contact__c=contact.id);
        insert service;
        DedupActiveServicesBatch sbc = new DedupActiveServicesBatch();
        Database.executeBatch(sbc, 10);
    }


    private static Contact createContact(Account account) {
        return new Contact(
                AccountId = account.Id,
                FirstName = 'Test Contact',
                LastName = 'Last name test contact',
                Email = 'testEmail@exemple.com',
                MobilePhone = '99999999'
        );

    }

    private static Account createAccount() {
        return new Account(
                Name = 'Test Account',
                Type = 'Agency',
                Active__c = true
        );
    }
}