public with sharing class DedupActiveServicesBatch implements Database.Batchable<SObject>{

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator([
                SELECT Id, Name, Contact__c, Address__c
                FROM Service__c
                WHERE IsActive__c = TRUE
        ]);
    }
    
    public void execute(Database.BatchableContext BC, List<SObject> requestList){
        // call service from here
        if(!requestList.isEmpty() && requestList != null){
//            ServiceService.newInstance(requestList).dedupActiveRequests();
        }
    }

    public void finish(Database.BatchableContext context) {
    }
}