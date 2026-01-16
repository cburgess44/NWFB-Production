/**
 * Created by Gustavo on 08/01/24.
 */

@IsTest
private class TripExceptionDaoTest {
    @TestSetup
    static void setup() {
        Location__c location = new Location__c(
                Name = 'Test'
        );
        insert location;
        DispatcherException__c dispatcherException = new DispatcherException__c(
                Name = 'Test',
                UniqueField__c = '22123',
                TimeFrame__c = 'Morning',
                Location__c = location.Id
        );
        insert dispatcherException;
    }

    @IsTest
    static void validateUniqueCreation() {
        try {
            Location__c location = [SELECT Id FROM Location__c LIMIT 1];

            DispatcherException__c duplicateDispatcherException = new DispatcherException__c(
                    Name = 'Test',
                    UniqueField__c = '22123',
                    TimeFrame__c = 'Morning',
                    Location__c = location.Id
            );
            insert duplicateDispatcherException;
            System.assert(duplicateDispatcherException.Id == null);
        } catch (Exception e) {
            System.assert(e != null);
        }
    }
}