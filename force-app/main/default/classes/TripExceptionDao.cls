/**
 * Created by Eric Solari on 02/05/2023.
 */

public with sharing class TripExceptionDao extends GenericDao{

    @TestVisible
    private static TripExceptionDao mock;

    public TripExceptionDao() {
    }

    private TripExceptionDao(List<SObject> services, Map<Id, SObject> oldServicesById) {
        super(services, oldServicesById);
    }

    private TripExceptionDao(List<SObject> services) {
        super(services);
    }

    public static TripExceptionDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new TripExceptionDao(new List<DispatcherException__c>());
        }
    }

    public override void afterInsert() {

    }

    public override void beforeInsert() {
        validateUniqueCreation();
    }

    public void validateUniqueCreation(){
        Set<String> uniquesStrings = new Set<String>();

        for(DispatcherException__c dispatcherException: (List<DispatcherException__c>) this.records){
            String uniqueString = '' + dispatcherException.RecordTypeId + dispatcherException.Location__c + dispatcherException.Date__c;
            dispatcherException.UniqueField__c = uniqueString;
            uniquesStrings.add(uniqueString);
        }

        //TODO put this in a selector
        Map<String, SObject> createdExceptions = Utils.listToStringMap(
                DispatcherException__c.UniqueField__c,
                [SELECT Id, UniqueField__c FROM DispatcherException__c WHERE UniqueField__c IN: uniquesStrings]
        );

        for(DispatcherException__c dispatcherException: (List<DispatcherException__c>) this.records){
           if (!createdExceptions.containsKey(dispatcherException.UniqueField__c)) continue;
           dispatcherException.addError('There is already an exception created for the informed date and location. Edit the existing exception or create a new one with another date or location.');
        }
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new TripExceptionDao(objects, oldObjectsById);
        }
    }
}