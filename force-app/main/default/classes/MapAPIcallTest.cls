@isTest
public class MapAPIcallTest {
    @isTest
    static void apicallTest1(){
       

        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MapApiCallMock());
        String answer= MapsAPICallout.callMapDirections('123something');
        System.assertEquals('{"routes":[]}', answer);
        Test.stopTest();

        
    }
}