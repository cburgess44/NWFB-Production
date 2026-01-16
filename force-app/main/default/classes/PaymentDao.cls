public without sharing class PaymentDao extends GenericDao {
    @TestVisible
    private static PaymentDao mock;

    public PaymentDao() {
    }

    private PaymentDao(List<SObject> payments, Map<Id, SObject> oldPaymentsById) {
        super(payments, oldPaymentsById);
    }
    private PaymentDao(List<SObject> payments) {
        super(payments);
    }

    public static PaymentDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new PaymentDao(new List<Payment__c>());
        }
    }

    public override void afterInsert() {
        sendRefundEmail();
//        sendEmailByStatus();
//        rollUpInvoiceAmountDue();
        rollup();
    }
    public override void afterUpdate() {
//        sendEmailByStatus();
//        rollUpInvoiceAmountDue();
        rollup();
    }

    public override void afterDelete() {
//        rollUpInvoiceAmountDue();
        rollup();
    }

    private void rollup() {
        if (this.records != null && !this.records.isEmpty()) {
            Database.update(dlrs.RollupService.rollup(this.records));
        }
    }

//    private void sendEmailByStatus() {
//        Map<Id, SObject> newRecordsMap = new Map<Id, SObject>(this.records);
//        Map<Id, SObject> oldPayments = (Map<Id, SObject>) this.oldRecordsById;
//        Set<Id> invoiceIds = new Set<Id>();
//
//        for (Payment__c payment : (List<Payment__c>) newRecordsMap.values()) {
//            if (payment.Invoice__c == null) continue;
//
//            invoiceIds.add(payment.Invoice__c);
//        }
//
//        List<String> emailTemplateNames = new List<String>{
//            'PaymentCompleted'
//        };
//
//        Map<String, EmailTemplate> emailTemplatesByNameMap = EmailTemplateSelector.getInstance().getEmailTemplatesByDeveloperNames(emailTemplateNames);
//        Map<Id, Invoice__c> invoiceMap = new Map<Id, Invoice__c>(InvoiceSelector.getInstance().getInvoicesByIds(invoiceIds));
//        Map<String, OrgWideEmailAddress> addressToOrgWideEmail = OrgWideEmailAddressSelector.getInstance().getOrgWideEmailAddressByEmailAddress('clientservices@nwfurniturebank.org');
//
//        for(Payment__c payment : (List<Payment__c>) newRecordsMap.values()){
//            Payment__c oldPayment = (Payment__c)oldPayments?.get(payment.Id);
//
//            if (payment.Status__c != 'Approved' || (payment.Status__c == oldPayment.Status__c)) continue;
//
////            sendEmail(emailTemplatesByNameMap.get('PaymentCompleted'), invoiceMap.get(payment.Invoice__c), addressToOrgWideEmail.get('clientservices@nwfurniturebank.org').Id);
//        }
//    }

//    private void sendEmail(EmailTemplate emailTemplatesByNameMap, Invoice__c invoice, Id orgWideEmailAddressId) {
//        List<String> toEmailAddressList = new List<String>{
//                invoice.Service__r.Contact__r.Email
//        };
//
//        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//        mail.setTemplateId(emailTemplatesByNameMap.Id);
//        mail.setToAddresses(toEmailAddressList);
//        mail.setTargetObjectId(invoice.Service__c);
//        mail.setSaveAsActivity(false);
//        mail.setOrgWideEmailAddressId(orgWideEmailAddressId);
//
//        List<Messaging.SingleEmailMessage> emailMessageList = new List<Messaging.SingleEmailMessage>{
//                mail
//        };
//
//        try {
//            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emailMessageList);
//            System.debug('results ' + results);
//
//        } catch (Exception e) {
//            System.debug(e.getMessage());
//        }
//    }
    @TestVisible
    private void sendRefundEmail() {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        EmailTemplate paymentRefundEmailTemplate = new EmailTemplateSelector().getEmailTemplateByName('Payment Refund');

        Map<String, OrgWideEmailAddress> orgWideEmailAddressByEmail = OrgWideEmailAddressSelector.getInstance()
                .getOrgWideEmailAddressByEmailAddress('clientservices@nwfurniturebank.org');

        Set<Id> paymentIds = new Set<Id>();

        for (Payment__c payment : (List<Payment__c>) records) {
            paymentIds.add(payment.Id);
        }

        Map<Id, SObject> paymentsByIds = Utils.listToMap(
                'Id',
                PaymentSelector.getInstance().byIds(paymentIds)
        );

        for (Payment__c pm : (List<Payment__c>) records) {
            Payment__c payment = (Payment__c) paymentsByIds.get(pm.Id);

            if (payment.PaymentMethod__c == 'CreditCard') continue;
            if (payment.PaymentType__c != 'Refund') continue;

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setTemplateId(paymentRefundEmailTemplate.Id);
            mail.setToAddresses(new List<String>{
                    'ap@nwfurniturebank.org'
            });
            mail.setTargetObjectId(payment.Service__r.Contact__c);
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setWhatId(payment.Id);
            mail.setSaveAsActivity(false);
//            mail.setOrgWideEmailAddressId(orgWideEmailAddressByEmail.get('clientservices@nwfurniturebank.org').Id);
            emails.add(mail);
            System.debug('Added Email');
        }

        try {
            List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }


//    @TestVisible
//    private void rollUpInvoiceAmountDue(){
    // Map<Id, SObject> newRecordsMap = new Map<Id, SObject>(this.records);
    // Set<Id> invoiceIdSet = new Set<Id>();
    // for(Payment__c payment : (List<Payment__c>) newRecordsMap.values()){
    //     invoiceIdSet.add(payment.Invoice__c);
    // }
    // invoiceIdSet.remove(null);
    // Map<Id, Invoice__c> invoicesMap = new Map<Id, Invoice__c>(InvoiceSelector.getInstance().getInvoicesByIds(invoiceIdSet));
    // for(Payment__c payment : (List<Payment__c>) newRecordsMap.values()){
    //     if(String.isNotBlank(payment.Invoice__c)){
    //         Invoice__c invoice = invoicesMap.get(payment.Invoice__c);
    //         if(invoice.TotalPaid__c == null){
    //             invoice.TotalPaid__c = 0;
    //         }
    //         invoice.TotalPaid__c += payment.PaymentAmount__c;
    //         invoicesMap.put(payment.Invoice__c, invoice);
    //     }
    // }
    // update invoicesMap.values();
//    }


    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new PaymentDao(objects, oldObjectsById);
        }
    }
}