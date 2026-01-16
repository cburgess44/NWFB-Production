/**
 * Created by Gustavo on 11/03/24.
 */

public with sharing class OpportunityDao extends GenericDao {

    @TestVisible
    private static OpportunityDao mock;

    public OpportunityDao() {
    }

    public static OpportunityDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new OpportunityDao(new List<Opportunity>());
        }
    }

    private OpportunityDao(List<SObject> opportunities, Map<Id, SObject> oldOpportunitiesById) {
        super(opportunities, oldOpportunitiesById);
    }

    private OpportunityDao(List<SObject> opportunities) {
        super(opportunities);
    }

    public override void afterUpdate() {
        createPaymentAndCharge();
    }

    private void createPaymentAndCharge() {
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> opportunities, Map<Id, SObject> oldOpportunitiesById) {
            return new OpportunityDao(opportunities, oldOpportunitiesById);
        }
    }
}