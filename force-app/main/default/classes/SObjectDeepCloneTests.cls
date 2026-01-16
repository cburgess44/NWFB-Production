@IsTest
private class SObjectDeepCloneTests {

    @IsTest static void accountWithContacts() {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.duplicateRuleHeader.allowSave = true;

        Account acc = createAccount();
        Database.insert(acc, dml) ;

        Map<String, Contact> contactsByName = new Map<String, Contact>();
        for (Integer i = 0; i < 5; i++) {
            String shiftName = Math.random().format() + System.now().format('yyyyMMddhhmmss');
            Contact c = createContact(acc.Id, 'Contact'+shiftName, shiftName + String.valueOf(i));
            contactsByName.put(c.FirstName + c.LastName, c);
        }

        Database.insert(contactsByName.values(), dml) ;

        //pass opportunities just to test query gen on multiple children
        SObjectDeepClone cloner = new SObjectDeepClone(acc.Id, new Set<String>{
                'contacts', 'opportunities'
        });
        String cloneName = acc.Name + ' Copy';
        Account toBeCloned = (Account) cloner.clone;
        toBeCloned.Name = cloneName;   //change name
        Id clonedId = cloner.save();
        System.assertNotEquals(null, clonedId);
        System.assertNotEquals(acc.Id, clonedId);

        Account queriedClonedAccount = [SELECT Name, (SELECT FirstName, LastName FROM Contacts) FROM Account WHERE Id = :clonedId];

        System.assertEquals(cloneName, queriedClonedAccount.Name);
        System.assertEquals(contactsByName.size(), queriedClonedAccount.Contacts.size());
        for (Contact c : queriedClonedAccount.Contacts) {
            Contact orgContact = contactsByName.get(c.FirstName + c.LastName);
            System.assertNotEquals(null, orgContact);
        }
    }

    //== OBJECT CREATORS... Might need to adjust to pass ORG validations
    private static Account createAccount() {
        return new Account(
                Name = 'abc'              
        );
    }

    private static Contact createContact(Id accId, String firstName, String lastName) {
        return new Contact(
                AccountId = accId,
                FirstName = firstName,
                LastName = lastName,
                Email = lastName+'@example.com'

        );
    }

}