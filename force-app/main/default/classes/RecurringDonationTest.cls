/**
 * Created by Gustavo on 28/03/24.
 */
@IsTest
public with sharing class RecurringDonationTest {
    @IsTest
    public static void testInsert() {
        Contact ctt = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert ctt;

        npe03__Recurring_Donation__c recurringDonation = new npe03__Recurring_Donation__c(
                npe03__Amount__c = 3,
                npe03__Contact__c = ctt.Id
        );

        insert recurringDonation;

        System.assert(recurringDonation.npe03__Amount__c != null);

    }
}