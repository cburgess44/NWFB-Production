/**
 * Created by Eric Solari on 05/04/2023.
 */

public with sharing class ProductSelector {
    private static ProductSelector instance = null;

    public static ProductSelector getInstance() {
        if (instance == null) {
            instance = new ProductSelector();
        }
        return instance;
    }

    public Map<Id, Product__c> getMapProductById(Set<Id> productsIds){
        return new Map<Id, Product__c>([SELECT Id, Pick_up_Fee__c, Estimated_Value__c, Product_Fee__c, Taxable__c FROM Product__c WHERE id IN: productsIds]);
    }
}