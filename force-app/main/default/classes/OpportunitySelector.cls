/**
 * Created by Gustavo on 02/04/24.
 */

public with sharing class OpportunitySelector {
    public static OpportunitySelector newInstance() {
        return new OpportunitySelector();
    }

    public List<Opportunity> getFutureOpportunitiesByRecurringDonation(Set<Id> recurringDonationIds){
        return [
                SELECT
                        Id,
                        Name,
                        PaymentToken__c,
                        Amount,
                        CloseDate,
                        npe03__Recurring_Donation__c
                FROM Opportunity
                WHERE npe03__Recurring_Donation__c IN: recurringDonationIds
        ];
    }
}