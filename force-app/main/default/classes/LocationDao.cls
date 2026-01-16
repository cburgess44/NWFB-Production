/**
 * Created by Gustavo on 01/03/23.
 */

public without sharing class LocationDao extends GenericDao{

    @TestVisible
    private static LocationDao mock;

    public static LocationDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new LocationDao(new List<Location__c>());
        }
    }

    private LocationDao(List<SObject> requests, Map<Id, SObject> oldRequestsById) {
        super(requests, oldRequestsById);
    }
    private LocationDao(List<SObject> requests) {
        super(requests);
    }

    public override void afterInsert() {
        rollup();
    }

    public override void afterUpdate() {
        rollup();
    }

    public override void beforeInsert() {
        updateEmailByCity();
    }

    private void updateEmailByCity() {
        for (Location__c location : (List<Location__c>) this.records) {
            if (location.City__c == null) continue;

            location.LocationEmail__c = location.City__c == 'Tacoma'
                    ? 'clientservices@nwfurniturebank.org'
                    : 'vaninfo@nwfurniturebank.org';
        }
    }

    private void rollup() {
        if (this.records != null && !this.records.isEmpty()) {
            Database.update(dlrs.RollupService.rollup(this.records));
        }
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new LocationDao(objects, oldObjectsById);
        }
    }
}