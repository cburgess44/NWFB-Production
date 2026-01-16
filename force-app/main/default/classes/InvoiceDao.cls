public with sharing class InvoiceDao extends GenericDao {
    @TestVisible
    private static InvoiceDao mock;

    public InvoiceDao() {
    }

    private InvoiceDao(List<SObject> invoices, Map<Id, SObject> oldInvoicesById) {
        super(invoices, oldInvoicesById);
    }
    private InvoiceDao(List<SObject> invoices) {
        super(invoices);
    }

    public static InvoiceDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new InvoiceDao(new List<Invoice__c>());
        }
    }

    public override void afterInsert() {
        createInvoiceItems();
        setCreateInvoiceDate(false);
    }
    public override void beforeInsert() {
        setDueDate();
    }
    public override void beforeUpdate() {
        setDueDate();
    }
    public override void afterUpdate() {
        sendEmailWhenSubmitted();
    }

    public override void afterDelete(){
        setCreateInvoiceDate(true);
    }

    public void setCreateInvoiceDate(Boolean clearField){
        List<Service__c> servicesToUpdate = new List<Service__c>();
        Set<Id> servicesIds = new Set<Id>();

        for (Invoice__c invoice : (List<Invoice__c>) this.records) {
            servicesIds.add(invoice.Service__c);
        }

        for (Id serviceId : servicesIds) {
            if (clearField) {
                servicesToUpdate.add(
                        new Service__c(
                                Id = serviceId,
                                InvoiceCreated__c = null
                        )
                );
                continue;
            }

            servicesToUpdate.add(
                    new Service__c(
                            Id = serviceId,
                            InvoiceCreated__c = System.now()
                    )
            );
        }

        update servicesToUpdate;
    }
    
    @TestVisible
    private void setDueDate(){
        Map<Id, Invoice__c> oldRecordsMap = (Map<Id, Invoice__c>) this.oldRecordsById;

        for (Invoice__c inv : (List<Invoice__c>) this.records) {
            if (oldRecordsMap == null) continue;
            if (inv.CreateDate__c == oldRecordsMap.get(inv.Id).CreateDate__c || inv.CreateDate__c == null) continue;

            inv.DueDate__c = inv.CreateDate__c.addDays(30);
        }
    }

    @TestVisible
    private void createInvoiceItems(){
        List<ServiceCharge__mdt> mapsSettings = [
                SELECT
                        DeliveryCost__c,
                        Quantity__c,
                        WillCallCost__c
                FROM ServiceCharge__mdt
        ];
        Map<Decimal,ServiceCharge__mdt> priceMap = new Map<Decimal,ServiceCharge__mdt>();

        for (ServiceCharge__mdt scm : mapsSettings) {
            priceMap.put(scm.Quantity__c,scm);
        }
        
        Map<Id, Invoice__c> newRecordsMap = new Map<Id, Invoice__c>((List<Invoice__c>) this.records);
        Set<Id> requestIdSet = new Set<Id>();

        for (Invoice__c inv : newRecordsMap.values()) {
            requestIdSet.add(inv.Service__c);
        }

        requestIdSet.remove(null);

        Map<Id,Service__c> requestMap = new Map<Id,Service__c>(
                ServiceSelector.getInstance().getServiceByIdsAndItemsByCategory(requestIdSet)
        );
        List<InvoiceItem__c> invItemInsertList = new List<InvoiceItem__c>();

        for (Invoice__c inv : newRecordsMap.values()) {
            InvoiceItem__c invItem = new InvoiceItem__c(
                    Name = 'Delivery charge Item',
                    Invoice__c = inv.Id,
                    Type__c = 'Delivery charge',
                    Price__c = 125
            );
            invItemInsertList.add(invItem);

            invItem = new InvoiceItem__c(
                    Name = 'Processing Fee Item',
                    Invoice__c = inv.Id,
                    Type__c = 'Processing Fee'
            );
            Decimal price = 0;

            Service__c service = requestMap.get(inv.Service__c);

            if (service != null && service.ServiceItems__r != null && service.ServiceItems__r.size() > 0) {
                price = priceMap.get(service.ServiceItems__r.size()).DeliveryCost__c;
            }

            invItem.Price__c = price;
            invItemInsertList.add(invItem);
        }

        insert invItemInsertList;
    }
    @TestVisible
    private void sendEmailWhenSubmitted(){
        Map<Id, Invoice__c> newRecordsMap = new Map<Id, Invoice__c>((List<Invoice__c>) this.records);
        Map<Id, Invoice__c> oldRecordsMap = (Map<Id, Invoice__c>) this.oldRecordsById;

        Set<Id> contactIdSet = new Set<Id>();

        for (Invoice__c inv : newRecordsMap.values()) {
            if (oldRecordsMap == null) continue;
            Invoice__c oldInvoice = oldRecordsMap.get(inv.Id);

            if (inv.Status__c == 'Submitted' && oldInvoice.Status__c == 'Submitted') continue;

            contactIdSet.add(inv.Caseworker__c);
        }
        contactIdSet.remove(null);
        sendEmailToCaseworkerAndRelatedApContacts(contactIdSet);        
    }

    @TestVisible
    private static void sendEmailToCaseworkerAndRelatedApContacts(Set<Id> contactIdSet){
        EmailTemplate emailTemplate = EmailTemplateSelector.getInstance().getEmailTemplateByName('InvoiceTemplate');
        List<Contact> contactsToNotify = ContactSelector.getInstance().getCaseWorkersAndRelatedApContacts(contactIdSet);
        Map<Id,Id> contactInvoiceIdMap = new Map<Id,Id>();
        Messaging.SingleEmailMessage mail;
        List<Messaging.SingleEmailMessage> mailsList = new List<Messaging.SingleEmailMessage>();

        for(Contact con : contactsToNotify){
            mail = new Messaging.SingleEmailMessage();
            mail.setTargetObjectId(con.Id);
            mail.setWhatId(contactInvoiceIdMap.get(con.Id));
            mail.setTemplateId(emailTemplate.Id);
            mailsList.add(mail);
        }
        //send the email
        Messaging.sendEmail(mailsList);
        
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new InvoiceDao(objects, oldObjectsById);
        }
    }
}