public without sharing class InvoiceSelector {

//    private static InvoiceSelector instance = null;
//
//    public static InvoiceSelector getInstance() {
//        if (instance == null) {
//        instance = new InvoiceSelector();
//        }
//        return instance;
//    }
//
//    public Map<Id, Invoice__c> getInvoicesByIds(Set<Id> invoiceIds){
//        return new Map<Id, Invoice__c>([
//                SELECT Id,Name, TotalPaid__c, Service__r.Delivery_Fee__c,
//                    Service__r.Processing_Fee__c, Service__r.Contact__r.Email
//                FROM Invoice__c
//                WHERE id IN :invoiceIds]);
//    }
//
//    public Invoice__c getInvoiceById( Id invoiceId){
//        return [SELECT Id, Name, TotalPaid__c, Service__c FROM Invoice__c WHere Id= :invoiceId];
//    }

}