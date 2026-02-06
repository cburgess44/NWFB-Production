/**
 * Tests for ContactDao, including preferred contact defaults on insert.
 */
@IsTest
private class ContactDaoTest {

    @IsTest
    static void testPreferredContactDefaultsOnInsert() {
        Contact contact = new Contact(
                FirstName = 'Preferred',
                LastName = 'Defaults',
                npe01__PreferredPhone__c = 'Work',
                npe01__Preferred_Email__c = null
        );
        insert contact;

        Contact inserted = [SELECT npe01__PreferredPhone__c, npe01__Preferred_Email__c FROM Contact WHERE Id = :contact.Id];
        System.assertEquals('Mobile', inserted.npe01__PreferredPhone__c, 'Preferred Phone should default to Mobile');
        System.assertEquals('Personal', inserted.npe01__Preferred_Email__c, 'Preferred Email should default to Personal');
    }

    @IsTest
    static void testPreferredEmailWorkOverriddenToPersonal() {
        Contact contact = new Contact(
                FirstName = 'Email',
                LastName = 'WorkTest',
                npe01__PreferredPhone__c = 'Mobile',
                npe01__Preferred_Email__c = 'Work'
        );
        insert contact;

        Contact inserted = [SELECT npe01__Preferred_Email__c FROM Contact WHERE Id = :contact.Id];
        System.assertEquals('Personal', inserted.npe01__Preferred_Email__c, 'Preferred Email Work should be overridden to Personal');
    }

    @IsTest
    static void testPreferredContactDefaultsWhenBlank() {
        Contact contact = new Contact(
                FirstName = 'Blank',
                LastName = 'Defaults'
        );
        insert contact;

        Contact inserted = [SELECT npe01__PreferredPhone__c, npe01__Preferred_Email__c FROM Contact WHERE Id = :contact.Id];
        System.assertEquals('Mobile', inserted.npe01__PreferredPhone__c, 'Preferred Phone should default to Mobile when blank');
        System.assertEquals('Personal', inserted.npe01__Preferred_Email__c, 'Preferred Email should default to Personal when blank');
    }

    @IsTest
    static void testPreferredContactDefaultsPreservedWhenMobileAndPersonal() {
        Contact contact = new Contact(
                FirstName = 'Already',
                LastName = 'Set',
                npe01__PreferredPhone__c = 'Mobile',
                npe01__Preferred_Email__c = 'Personal'
        );
        insert contact;

        Contact inserted = [SELECT npe01__PreferredPhone__c, npe01__Preferred_Email__c FROM Contact WHERE Id = :contact.Id];
        System.assertEquals('Mobile', inserted.npe01__PreferredPhone__c, 'Preferred Phone should be preserved when Mobile');
        System.assertEquals('Personal', inserted.npe01__Preferred_Email__c, 'Preferred Email should be preserved when Personal');
    }

    @IsTest
    static void testAlternateAndHomeOverriddenToDefaults() {
        Contact contact = new Contact(
                FirstName = 'Override',
                LastName = 'Test',
                npe01__PreferredPhone__c = 'Home',
                npe01__Preferred_Email__c = 'Alternate'
        );
        insert contact;

        Contact inserted = [SELECT npe01__PreferredPhone__c, npe01__Preferred_Email__c FROM Contact WHERE Id = :contact.Id];
        System.assertEquals('Mobile', inserted.npe01__PreferredPhone__c, 'Home should be overridden to Mobile');
        System.assertEquals('Personal', inserted.npe01__Preferred_Email__c, 'Alternate should be overridden to Personal');
    }

    @IsTest
    static void testUpdateMobilePhoneOnInsert() {
        Contact contact = new Contact(
                FirstName = 'Mobile',
                LastName = 'Test',
                MobilePhone = '5551234567'
        );
        insert contact;

        Contact inserted = [SELECT MobilePhone FROM Contact WHERE Id = :contact.Id];
        System.assertEquals('15551234567', inserted.MobilePhone, 'Mobile should be prefixed with 1');
    }

    @IsTest
    static void testContactUpdateTriggersBeforeUpdate() {
        Contact contact = new Contact(FirstName = 'Update', LastName = 'Test');
        insert contact;
        contact.FirstName = 'Updated';
        update contact;
        System.assert(true, 'Update completes');
    }

    @IsTest
    static void testGetInstanceWithMock() {
        ContactDao.mock = new ContactDao();
        ContactDao result = ContactDao.getInstance();
        System.assertEquals(ContactDao.mock, result, 'Should return mock when set');
        ContactDao.mock = null;
    }
}
