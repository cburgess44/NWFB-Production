/**
 * Created by Eric Solari on 04/01/2024.
 */
@isTest
public with sharing class CustomRequestItemsControllerTest {
    @IsTest
    public static void testGetRecords(){
        Map<String, Id> ret = new Map<String, Id>();
        ret = CustomRequestItemsRelatedListController.getRecordTypeIdsByObject('Service__c');
        System.assertEquals(true, ret.values().size()>0);
    }
}