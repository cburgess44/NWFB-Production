/**
 * Created by Eric Solari on 03/01/2024.
 */
@IsTest
public with sharing class AreaSelectorTest {

    @IsTest
    public static void testSelector(){
        Area__c area = new Area__c(Name = 'area test', ZipCode__c='1234');
        insert area;

        List<Area__c> areasById = AreaSelector.getInstance().getAreaByIds(new Set<Id>{area.Id});
        List<Area__c> areasByZipCode = AreaSelector.getInstance().getAreaByZipCode(new Set<String>{area.ZipCode__c});
        System.assertEquals(1, areasById.size());
        System.assertEquals(1, areasByZipCode.size());
    }
}