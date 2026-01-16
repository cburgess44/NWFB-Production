/**
 * Created by Gustavo on 29/06/23.
 */

public without sharing class PaymentSelector {

    private static PaymentSelector instance = null;

    public static PaymentSelector getInstance() {
        if (instance == null) {
            instance = new PaymentSelector();
        }
        return instance;
    }

    public List<Payment__c> byIds(Set<Id> ids){
        return [
            SELECT
                Id,
                Name,
                Service__c,
                PaymentMethod__c,
                Payee_Type__c,
                PaymentType__c,
                Service__r.Contact__c,
                Service__r.Name
            FROM Payment__c
            WHERE Id IN :ids
        ];
    }
}