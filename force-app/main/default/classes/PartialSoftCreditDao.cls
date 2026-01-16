/**
 * Created by Gustavo on 20/03/24.
 */

public with sharing class PartialSoftCreditDao extends GenericDao {
    @TestVisible
    private static PartialSoftCreditDao mock;

    public PartialSoftCreditDao() {
    }

    public static PartialSoftCreditDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new PartialSoftCreditDao(new List<npsp__Account_Soft_Credit__c>());
        }
    }

    private PartialSoftCreditDao(List<SObject> partialSoftCredits, Map<Id, SObject> oldPartialSoftCreditsById) {
        super(partialSoftCredits, oldPartialSoftCreditsById);
    }

    private PartialSoftCreditDao(List<SObject> partialSoftCredits) {
        super(partialSoftCredits);
    }

    public override void beforeInsert() {
        populateAccount();
    }

    public void populateAccount() {
        Set<Id> contactIds = new Set<Id>();

        for (npsp__Partial_Soft_Credit__c partialSoftCredit : (List<npsp__Partial_Soft_Credit__c>) records) {
            if (partialSoftCredit.npsp__Contact__c == null) continue;
            contactIds.add(partialSoftCredit.npsp__Contact__c);
        }

        Map<Id, SObject> contactById = Utils.listToMap(
                'Id',
                ContactSelector.getInstance().getContactsByIds(contactIds)
        );

        for (npsp__Partial_Soft_Credit__c partialSoftCredit : (List<npsp__Partial_Soft_Credit__c>) records) {
            if (partialSoftCredit.npsp__Contact__c == null) continue;
            Contact contact = (Contact) contactById.get(partialSoftCredit.npsp__Contact__c);
            if (contact == null) continue;

            partialSoftCredit.Account__c = contact.AccountId;
        }
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> partialSoftCredits, Map<Id, SObject> oldPartialSoftCreditsById) {
            return new PartialSoftCreditDao(partialSoftCredits, oldPartialSoftCreditsById);
        }
    }
}