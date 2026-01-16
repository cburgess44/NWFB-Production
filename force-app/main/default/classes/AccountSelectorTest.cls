/**
 * Created by Eric Solari on 03/01/2024.
 */
@IsTest
public with sharing class AccountSelectorTest {

    @IsTest
    public static void selectorTest(){
        Account account = createAccount();
        insert account;
        Set<Id> idsSet = new Set<Id> {account.Id};
        Map<Id, Account> accounts = AccountSelector.getInstance().getAccountsByIds(idsSet);
        System.assertEquals(1, accounts.values().size());
    }

    private static Account createAccount() {
        return new Account(
                Name = 'Test Account',
                Type = 'Agency',
                Active__c = true
        );
    }
}