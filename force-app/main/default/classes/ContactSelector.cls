public without sharing class ContactSelector {

    private static ContactSelector instance = null;

    public static ContactSelector getInstance() {
        if (instance == null) {
        instance = new ContactSelector();
        }
        return instance;
    }

    public List<Contact> getContactsByIds(Set<Id> contactIdset){
        return [
            SELECT
                    Id,
                    MobilePhone,
                    Email,
                    FirstName,
                    AccountId,
                    CloverConnectProfileId__c,
                    DefaultPaymentMethodToken__c
            FROM Contact
            WHERE Id IN :contactIdset
        ];
    }

    public List<Contact> getContactsByMobilePhones(Set<String> contactMobilePhoneSet){
        String searchQuery = 'FIND \'' + contactMobilePhoneSet + '\' IN ALL FIELDS ';
        searchQuery += 'RETURNING Contact(Name, Phone, MobilePhone )';
        List<List<SObject>> searchResult = Search.query(
                searchQuery
        );

        return (List<Contact>) searchResult.get(0);
    }
    public List<Contact> getCaseWorkersAndRelatedApContacts(Set<Id> contactsIdSet){
        Map<Id,Contact> contactMap = new Map<Id,Contact>([
                SELECT Id
                FROM Contact
                WHERE Id IN :contactsIdSet
        ]);

        List<Contact> apContactList = [
                SELECT Id
                FROM Contact
                WHERE Id IN (SELECT APContact__c FROM AP_Contact__c WHERE Case_Worker__c IN :contactsIdSet)
        ];

        for (Contact con : apContactList) {
            contactMap.put(con.Id, con);
        }

        return contactMap.values();
    }

    public List<Contact> getContactApContacts(Id contactId){
        Map<Id,Contact> contactMap = new Map<Id, Contact>();
        List<Contact> apContactList = [
                SELECT  Id,
                        npe01__Preferred_Email__c,
                        npe01__WorkEmail__c,
                        npe01__HomeEmail__c,
                        npe01__AlternateEmail__c
                FROM Contact
                WHERE Id IN (SELECT APContact__c FROM AP_Contact__c WHERE Case_Worker__c = :contactId)
        ];

        for (Contact con : apContactList) {
            contactMap.put(con.Id, con);
        }

        return contactMap.values();
    }
}