/**
 * Created by Gustavo on 14/03/23.
 */

public without sharing class ContactDao extends GenericDao {

    @TestVisible
    private static ContactDao mock;

    public ContactDao() {
    }

    public static ContactDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new ContactDao(new List<Contact>());
        }
    }

    private ContactDao(List<SObject> contacts, Map<Id, SObject> oldContactsById) {
        super(contacts, oldContactsById);
    }

    private ContactDao(List<SObject> contacts) {
        super(contacts);
    }

    public override void afterInsert() {
        applyPreferredContactDefaultsAfterInsert();
        rollup();
    }

    public override void afterUpdate() {
        rollup();
        populatePaymentTokenOnRecurringDonations();
    }

    public override void beforeUpdate() {
        updateMobilePhone();
        calculateTotalServiceItemInThePast12Months();
    }

    public override void beforeInsert() {
        updateMobilePhone();
        setPreferredContactDefaults();
    }

    private void setPreferredContactDefaults() {
        for (Contact contact : (List<Contact>) this.records) {
            applyDefaultsToContact(contact);
        }
    }

    private void applyPreferredContactDefaultsAfterInsert() {
        List<Contact> toUpdate = new List<Contact>();
        for (Contact contact : (List<Contact>) this.records) {
            Boolean changed = false;
            if (!isPreferredPhoneMobile(contact.npe01__PreferredPhone__c)) {
                contact.npe01__PreferredPhone__c = 'Mobile';
                changed = true;
            }
            if (!isPreferredEmailPersonal(contact.npe01__Preferred_Email__c)) {
                contact.npe01__Preferred_Email__c = 'Personal';
                changed = true;
            }
            if (changed) {
                toUpdate.add(contact);
            }
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    private void applyDefaultsToContact(Contact contact) {
        if (!isPreferredPhoneMobile(contact.npe01__PreferredPhone__c)) {
            contact.npe01__PreferredPhone__c = 'Mobile';
        }
        if (!isPreferredEmailPersonal(contact.npe01__Preferred_Email__c)) {
            contact.npe01__Preferred_Email__c = 'Personal';
        }
    }

    private Boolean isPreferredPhoneMobile(String value) {
        return value != null && 'Mobile'.equalsIgnoreCase(value.trim());
    }

    private Boolean isPreferredEmailPersonal(String value) {
        return value != null && 'Personal'.equalsIgnoreCase(value.trim());
    }

    private void rollup() {
        if (this.records != null && !this.records.isEmpty()) {
            Database.update(dlrs.RollupService.rollup(this.records));
        }
    }

    private void calculateTotalServiceItemInThePast12Months() {
        Set<Id> contactIds = new Set<Id>();

        for (Contact contact : (List<Contact>) this.records) {
            contactIds.add(contact.Id);
        }

        Map<String, List<SObject>> serviceItems = Utils.listToMapLists(
                'Contact__c',
                new ServiceSelector().getServiceByContactIdAndDate(contactIds)
        );

        for (Contact contact : (List<Contact>) this.records) {
            List<Service__c> services = (List<Service__c>) serviceItems.get(contact.Id);

            if (services == null || services.isEmpty()) continue;

            Integer totalServiceItems = 0;

            for (Service__c service : services) {
                if (service.ServiceItems__r == null) continue;
                totalServiceItems = totalServiceItems + service.ServiceItems__r.size();
            }

            contact.TotalItemsInThePast12Months__c = totalServiceItems;
        }
    }

    private void updateMobilePhone() {
        for (Contact contact : (List<Contact>) this.records) {
            if (contact.MobilePhone == null) continue;
            if (contact.MobilePhone.startsWith('1')) continue;
            contact.MobilePhone = '1' + contact.MobilePhone;
        }
    }

    private void populatePaymentTokenOnRecurringDonations() {
        Set<Id> contactIds = new Map<Id, Contact>((List<Contact>) records).keySet();

        if (contactIds == null || contactIds.isEmpty()) return;

        Map<String, List<SObject>> recurringDonationsByContactId = Utils.listToMapLists(
                'npe03__Contact__c',
                RecurringDonationSelector.getInstance().getByContactId(contactIds)
        );

        List<npe03__Recurring_Donation__c> pendingRecurringDonations = new List<npe03__Recurring_Donation__c>();

        for (Contact contact : (List<Contact>) records) {
            List<npe03__Recurring_Donation__c> recurringDonations = (List<npe03__Recurring_Donation__c>)
                    recurringDonationsByContactId.get(contact.Id);

            if (recurringDonations == null || recurringDonations.isEmpty()) continue;

            for (npe03__Recurring_Donation__c recurringDonation : recurringDonations) {
                if (contact.DefaultPaymentMethodToken__c == recurringDonation.PaymentToken__c) continue;
                if (recurringDonation.PaymentToken__c != null) continue; 

                recurringDonation.PaymentToken__c = contact.DefaultPaymentMethodToken__c;
                pendingRecurringDonations.add(recurringDonation);
            } 
        }

        if (pendingRecurringDonations.isEmpty()) return;
        update pendingRecurringDonations;
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> contacts, Map<Id, SObject> oldContactsById) {
            return new ContactDao(contacts, oldContactsById);
        }
    }
}