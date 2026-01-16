/**
 * Created by dudunato on 2019-08-12.
 */

@IsTest
private class GenericDaoTest {

    @IsTest
    static void testBehavior() {
    }

    @IsTest
    public static void listSObjects() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;

        List<SObject> objects = GenericDao.getInstance().listSObjects(
                'Contact',
                new List<String>{'Name'},
                'AND Name != NULL'
        );

        System.assert(objects != null && !objects.isEmpty());
    }

    @IsTest
    public static void saveSObjects() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );

        List<SObject> savedObjects = GenericDao.getInstance().saveSObjects(new List<SObject>{contact});

        System.assert(savedObjects != null && !savedObjects.isEmpty());
    }

    @IsTest
    public static void getPicklist() {
        List<PicklistEnum.Entry> picklistValues = GenericDao.getInstance().getPicklist('Service__c', 'Status__c');
        System.assert(picklistValues != null && !picklistValues.isEmpty());
    }

    @IsTest
    public static void deleteSObjects() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;
        List<SObject> deletedSObjects = GenericDao.getInstance().deleteSObjects(new List<SObject>{contact});


        System.assert(deletedSObjects != null && !deletedSObjects.isEmpty());
    }

    @IsTest
    public static void deleteSObjectsByFilter() {
        Contact contact = new Contact(
                FirstName = 'Test',
                LastName = 'Test'
        );
        insert contact;

        List<SObject> deletedSObjects = GenericDao.getInstance().deleteSObjectsByFilter(
                'Contact',
                'AND FirstName = \'Test\''
        );

        System.assert(deletedSObjects != null && !deletedSObjects.isEmpty());
    }
}