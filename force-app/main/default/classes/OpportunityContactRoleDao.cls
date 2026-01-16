/**
 * Created by Gustavo on 06/03/24.
 */

public with sharing class OpportunityContactRoleDao extends GenericDao{
    @TestVisible
    private static OpportunityContactRoleDao mock;

    private OpportunityContactRoleDao(List<SObject> opportunityContactRoles, Map<Id, SObject> oldOpportunityContactRoleById) {
        super(opportunityContactRoles, oldOpportunityContactRoleById);
    }

    private OpportunityContactRoleDao(List<SObject> opportunityContactRoles) {
        super(opportunityContactRoles);
    }

    public static OpportunityContactRoleDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new OpportunityContactRoleDao(new List<OpportunityContactRole>());
        }
    }

    public override void beforeInsert() {
        populateHouseholdAccountFromContact();
    }

    private void populateHouseholdAccountFromContact() {
        Set<Id> contactIds = new Set<Id>();

        for (OpportunityContactRole oppContactRole : (List<OpportunityContactRole>) records) {
            if (oppContactRole.ContactId == null) continue;
            contactIds.add(oppContactRole.ContactId);
        }

        Map<Id, SObject> contactById = Utils.listToMap(
                'Id',
                ContactSelector.getInstance().getContactsByIds(contactIds)
        );

        for (OpportunityContactRole oppContactRole : (List<OpportunityContactRole>) records) {
            if (oppContactRole.ContactId == null) continue;
            Contact contact = (Contact) contactById.get(oppContactRole.ContactId);

            oppContactRole.Contact__c = oppContactRole.ContactId;

            if (contact == null) continue;

            oppContactRole.HouseholdAccount__c = contact.AccountId;
        }
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new OpportunityContactRoleDao(objects, oldObjectsById);
        }
    }

}