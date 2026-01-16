public without sharing class AccountSelector {

    private static AccountSelector instance = null;

    public static AccountSelector getInstance() {
        if (instance == null) {
        instance = new AccountSelector();
        }
        return instance;
    }

    public Map<Id, Account> getAccountsByIds(Set<Id> accountIds){
        return new Map<Id, Account>([
                SELECT
                        Id,
                        Name,
                        Location__c,
                        ShippingAddress
                FROM Account
                WHERE Id IN: accountIds
        ]);
    }

    public List<Account> getById(Set<Id> accountIds){
        return [
                SELECT
                        Id,
                        Name,
                        Location__c,
                        OwnerId,
                        RecordTypeId
                FROM Account
                WHERE Id IN :accountIds
        ];
    }
}