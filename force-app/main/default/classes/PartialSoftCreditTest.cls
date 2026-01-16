/**
 * Created by Gustavo on 28/03/24.
 */

@IsTest
public with sharing class PartialSoftCreditTest {

    @IsTest
    public static void populateAccount() {
        Account account = new Account(
                Name = 'Test'
        );
        insert account;

        Contact contact = new Contact(
                AccountId = account.Id,
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;

        Opportunity opportunity = new Opportunity(
                Name = 'Test',
                StageName = 'Closed Won',
                CloseDate = Date.today(),
                ContactId = contact.Id,
                Amount = 1
        );
        insert opportunity;

        npsp__Partial_Soft_Credit__c partialSoftCredit = new npsp__Partial_Soft_Credit__c(
                npsp__Contact__c = contact.Id,
                npsp__Opportunity__c = opportunity.Id
        );
        insert partialSoftCredit;

        npsp__Partial_Soft_Credit__c updatedPartialSoftCredit = [
                SELECT Account__c
                FROM npsp__Partial_Soft_Credit__c
                WHERE Id = :partialSoftCredit.Id
                LIMIT 1
        ];

        System.assert(updatedPartialSoftCredit.Account__c != null);
    }
}