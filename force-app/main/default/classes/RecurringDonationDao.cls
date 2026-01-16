/**
 * Created by Gustavo on 15/03/24.
 */

public with sharing class RecurringDonationDao extends GenericDao{
    @TestVisible
    private static RecurringDonationDao mock;

    public RecurringDonationDao() {
    }

    public static RecurringDonationDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new RecurringDonationDao(new List<npe03__Recurring_Donation__c>());
        }
    }

    private RecurringDonationDao(List<SObject> recurringDonations, Map<Id, SObject> oldRecurringDonationsById) {
        super(recurringDonations, oldRecurringDonationsById);
    }

    private RecurringDonationDao(List<SObject> recurringDonations) {
        super(recurringDonations);
    }

    public override void beforeInsert() {
        populatePaymentToken();
    }

    public override void beforeUpdate() {
        updatePaymentTokenOpportunities();
    }

    public void populatePaymentToken() {
        Set<Id> contactIds = new Set<Id>();

        for (npe03__Recurring_Donation__c recurringDonation : (List<npe03__Recurring_Donation__c>) records) {
            if (recurringDonation.npe03__Contact__c == null) continue;
            contactIds.add(recurringDonation.npe03__Contact__c);
        }

        Map<Id, SObject> contactsById = Utils.listToMap(
                'Id',
                new ContactSelector().getContactsByIds(contactIds)
        );

        if (contactsById == null || contactsById.isEmpty()) return;

        for (npe03__Recurring_Donation__c recurringDonation : (List<npe03__Recurring_Donation__c>) records) {
            if (recurringDonation.npe03__Contact__c == null) continue;

            Contact contact = (Contact) contactsById.get(recurringDonation.npe03__Contact__c);
            if (contact == null || contact.DefaultPaymentMethodToken__c == null) continue;
            if (recurringDonation.PaymentToken__c != null) continue;

            recurringDonation.PaymentToken__c = contact.DefaultPaymentMethodToken__c;
        }
    }

    public void updatePaymentTokenOpportunities() {
        Set<Id> recurringDonationIds = new Set<Id>();

        for (npe03__Recurring_Donation__c recurringDonation : (List<npe03__Recurring_Donation__c>) records) {
            npe03__Recurring_Donation__c oldRecurringDonation = (npe03__Recurring_Donation__c) oldRecordsById.get(recurringDonation.Id);
            if (oldRecurringDonation == null
                    || oldRecurringDonation.PaymentToken__c == recurringDonation.PaymentToken__c) continue;

            recurringDonationIds.add(recurringDonation.Id);
        }
        
        Map<String, List<SObject>> opportunitiesByRecurringDonation = Utils.listToMapLists(
                'npe03__Recurring_Donation__c',
                new OpportunitySelector().getFutureOpportunitiesByRecurringDonation(recurringDonationIds)
        );

        if (opportunitiesByRecurringDonation == null || opportunitiesByRecurringDonation.isEmpty()) return;

        List<Opportunity> pendingOpportunities = new List<Opportunity>();

        for (npe03__Recurring_Donation__c recurringDonation : (List<npe03__Recurring_Donation__c>) records) {
            List<Opportunity> opportunities = (List<Opportunity>) opportunitiesByRecurringDonation.get(recurringDonation.Id);

            if (opportunities == null || opportunities.isEmpty()) continue;

            for (Opportunity opportunity : opportunities) {
                if (opportunity.PaymentToken__c == recurringDonation.PaymentToken__c) continue;
                System.debug('went here');
                opportunity.PaymentToken__c = recurringDonation.PaymentToken__c;
                pendingOpportunities.add(opportunity);
            }
        }

        if (pendingOpportunities == null || pendingOpportunities.isEmpty()) return;

        Database.update(pendingOpportunities);
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> recurringDonations, Map<Id, SObject> oldRecurringDonationsById) {
            return new RecurringDonationDao(recurringDonations, oldRecurringDonationsById);
        }
    }
}