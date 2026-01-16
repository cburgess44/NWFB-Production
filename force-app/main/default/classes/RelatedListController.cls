public class RelatedListController { 
 
    @AuraEnabled( cacheable=true )
    public static RelatedListWrapper fetchRecords( String listValues )  { 

        system.debug( 'values are ' + listValues );
        List < String > strList = listValues.split( '-' );
        system.debug( 'values are ' + strList );
        RelatedListWrapper objWrap = new RelatedListWrapper();
         
        if ( strList.size() == 4 ) { 

            String fieldValue = strList.get( 0 );
            String objectName = strList.get( 1 ); 
            String parentFieldAPIName = strList.get( 2 );
            String fields = strList.get( 3 );  
            String strSOQL = 'SELECT Id, Name,' + fields;
            strSOQL += ', ' + parentFieldAPIName;
            String filter = ' FROM ' + objectName + ' WHERE ' + parentFieldAPIName + ' = \'' + fieldValue + '\' '; 
            String strCountSOQL = ' SELECT COUNT() ' + filter;
            objWrap.recordCount = Database.countQuery( strCountSOQL );
            strSOQL += filter + ' LIMIT 100';
            objWrap.listRecords = Database.query( strSOQL ); 
             
        }   
        return objWrap; 

    }

    public class RelatedListWrapper {

        @AuraEnabled
        public List < SObject > listRecords;
        @AuraEnabled
        public Integer recordCount;

    }
    public class SalesforceObject{
        @AuraEnabled
        public String name{set;get;}
        @AuraEnabled
        public String label{set;get;}
    }
         
}