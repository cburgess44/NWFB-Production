public class RequestRelatedListController {
  
    public class RelatedListControllerWrapper {
        @AuraEnabled
        public Integer totalElements { get; set; }
        @AuraEnabled
        public List<Service__c> elements { get; set; }
    
            public RelatedListControllerWrapper(Integer totalElements, List<Service__c> elements) {
                this.totalElements = totalElements;
                this.elements = elements;
            }
        }

    @AuraEnabled
    public static RelatedListControllerWrapper getRequestCurrentPage(Id requestId,Integer pageNumber,Integer pageSize){
        Service__c currentRequest= [SELECT Id, Contact__c FROM Service__c WHERE Id=:requestId];

        if (currentRequest.Contact__c == null) {
            return new RelatedListControllerWrapper(0,new List<Service__c>() );
        }

        String queryTotal =
        'SELECT COUNT() FROM Service__c ' +
        'WHERE Contact__c = \'' +currentRequest.Contact__c + '\' AND Id != \''+requestId+'\' ';
        
        String query = 'SELECT Id, Name, Pickup_type__c, Scheduling_Contact__c, Expiration_Date__c,Tag_Color__c FROM Service__c' +
        '  WHERE contact__c =  \'' +currentRequest.Contact__c + '\' AND Id != \''+requestId+'\' ';

        Integer totalNumber = Database.countQuery(queryTotal);

        if (totalNumber ==0 ) return new RelatedListControllerWrapper(totalNumber,new List<Service__c>() );
        query += ' ORDER BY createdDate DESC  LIMIT :pageSize ';

        if (pageNumber > 0) {
            pageNumber *= pageSize;
            query += ' OFFSET : pageNumber ';
        }
        
        return new RelatedListControllerWrapper(totalNumber, Database.query(query));
    }
}