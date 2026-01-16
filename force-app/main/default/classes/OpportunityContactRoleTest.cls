/**
 * Created by Gustavo on 28/03/24.
 */
@IsTest
public with sharing class OpportunityContactRoleTest {

    @IsTest
    public static void populateHouseholdAccountFromContact() {
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

        OpportunityContactRole opportunityContactRole = new OpportunityContactRole(
                ContactId = contact.Id,
                OpportunityId = opportunity.Id
        );

        insert opportunityContactRole;

        OpportunityContactRole updatedOpportunityAccountRole = [
                SELECT HouseholdAccount__c
                FROM OpportunityContactRole
                WHERE Id = :opportunityContactRole.Id
                LIMIT 1
        ];

        System.assert(updatedOpportunityAccountRole.HouseholdAccount__c != null);

    }
}