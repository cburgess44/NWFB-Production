public with sharing class TaskSelector {
    private static TaskSelector instance = null;

    public static TaskSelector getInstance() {
        if (instance == null) {
            instance = new TaskSelector();
        }
        return instance;
    }

    public List<AggregateResult> getTaskByTypeAndId(Set<Id> WhatId, List<List<String>> taskTypeList){
        List<String> typeList = new List<String>();
        
        for(List<String> taskItemList : taskTypeList){
            for(String type : taskItemList){
                typeList.add(type);
            }
		}
        
        List<AggregateResult> aggreateResultList = [
            SELECT COUNT(Id) ContactAttemptsTotal__c, Type
            FROM Task 
            WHERE WhatId IN : WhatId AND Type IN : typeList
        	GROUP BY Type
        ];
        
        return aggreateResultList;
    }

    public List<Task> byWhoIdAndType(Set<Id> nameIds) {
        return [
                SELECT
                    WhoId,
                    WhatId,
                    Type,
                    MessageType__c,
                    Status,
                    Read__c
                FROM Task
                WHERE WhoId IN :nameIds AND MessageType__c = 'Outgoing'
                ORDER BY CreatedDate DESC
        ];
    }

    public List<Task> byId(Set<Id> ids) {
        return [
                SELECT
                    WhoId,
                    WhatId,
                    Type,
                    MessageType__c,
                    MobilePhone__c,
                    Status,
                    Read__c
                FROM Task
                WHERE Id IN :ids
        ];
    }

}