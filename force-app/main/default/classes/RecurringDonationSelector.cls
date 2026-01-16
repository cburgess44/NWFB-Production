/**
 * Created by Gustavo on 15/03/24.
 */

public with sharing class RecurringDonationSelector {

    public static RecurringDonationSelector instance = null;

    public static RecurringDonationSelector getInstance() {
        if (instance == null) {
            instance = new RecurringDonationSelector();
        }
        return instance;
    }

    public List<npe03__Recurring_Donation__c> getByContactId(Set<Id> contactIds) {
        return [
                SELECT
                        Id,
                        Name,
                        npe03__Contact__c,
                        npe03__Contact__r.DefaultPaymentMethodToken__c,
                        PaymentToken__c
                FROM npe03__Recurring_Donation__c
                WHERE npe03__Contact__c IN :contactIds
        ];
    }

}