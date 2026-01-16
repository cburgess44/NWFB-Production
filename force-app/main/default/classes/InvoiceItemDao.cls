public with sharing class InvoiceItemDao extends GenericDao{

    @TestVisible
    private static InvoiceItemDao mock;

    public InvoiceItemDao() {}

    private InvoiceItemDao(List<SObject> tasks, Map<Id, SObject> oldTasksById) {
        super(tasks, oldTasksById);
    }

    private InvoiceItemDao(List<SObject> invoiceItems) {
        super(invoiceItems);
    }

//    public static InvoiceItemDao getInstance() {
//        if (Test.isRunningTest() && mock != null) {
//            return mock;
//        } else {
//            return new InvoiceItemDao(new List<InvoiceItem__c>());
//        }
//    }
//
    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new InvoiceItemDao(objects, oldObjectsById);
        }
    }

//    public override void afterInsert() {
//    }
//
//    public override void beforeInsert() {
//        //setFees();
//    }
//
//    public override void beforeUpdate() {
//        //setFees();
//    }

//    private void setFees(){
//        Map<Id, InvoiceItem__c> invoiceIdToInvoiceItem = new Map<Id, InvoiceItem__c>();
//
//        for(InvoiceItem__c invoiceItem : (List<InvoiceItem__c>)this.records) {
//            invoiceIdToInvoiceItem.put(invoiceItem.Invoice__c, invoiceItem);
//        }
//
//        Map<Id, Invoice__c> relatedInvoice = (Map<Id, Invoice__c>)InvoiceSelector.getInstance().getInvoicesByIds(invoiceIdToInvoiceItem.keySet());
//
//        for(InvoiceItem__c invoiceItem : (List<InvoiceItem__c>)this.records){
//
//            if(relatedInvoice.get(invoiceItem.Invoice__c) == null || relatedInvoice.isEmpty()){continue;}
//
//            invoiceItem.Name = invoiceItem.Type__c;
//
//            if(invoiceItem.Type__c == 'Processing Fee'){
//                invoiceItem.Price__c = relatedInvoice.get(invoiceItem.Invoice__c)?.Service__r.Processing_Fee__c;
//
//            }else{
//                invoiceItem.Price__c =  relatedInvoice.get(invoiceItem.Invoice__c)?.Service__r.Delivery_Fee__c;
//
//            }
//        }
//    }
}