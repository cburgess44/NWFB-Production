/**
 * Created by Gustavo on 03/06/24.
 */

public with sharing class PaymentReceiptEmailSender {

    @Future(Callout=true)
    public static void send(Set<Id> paymentIds) {
        List<Payment__c> payments = new PaymentSelector().byIds(paymentIds);

        Set<Id> serviceIds = new Set<Id>();

        for (Payment__c payment : (List<Payment__c>) payments) {
            if (payment.Service__c == null) continue;
            serviceIds.add(payment.Service__c);
        }

        if (serviceIds == null || serviceIds.isEmpty()) return;

        Map<Id, SObject> serviceById = Utils.listToMap(
                'Id',
                new ServiceSelector().getServiceByIds(serviceIds)
        );

        EmailTemplate paymentReceivedEmailTemplate = new EmailTemplateSelector().getEmailTemplateByDeveloperName(
                'PaymentCompleted'
        );

        OrgWideEmailAddress infoOrgWideAddress = new OrgWideEmailAddressSelector().getOrgWideEmailAddress(
                'info@nwfurniturebank.org'
        );

        List<Service__c> services = new List<Service__c>();

        EmailCooker emailCooker = new EmailCooker();

        for (Payment__c payment : (List<Payment__c>) payments) {
            Service__c currentService = (Service__c) serviceById.get(payment.Service__c);
            if (currentService == null) continue;
            if (payment.PaymentType__c == 'Refund') continue;
            Messaging.EmailFileAttachment mailAttachment = null;

            if (!Test.isRunningTest())  {
                PageReference PDF = Page.InvoicePDF;
                PDF.getParameters().put('Id', currentService.Id);
                PDF.setRedirect(true);
                Blob b = PDF.getContent();

                Utils.createContentVersion(
                        'Invoice:' + currentService.InvoiceNumberVersion__c + '.pdf',
                        b,
                        currentService.Id
                );
                mailAttachment = new Messaging.EmailFileAttachment();
                mailAttachment.setBody(b);
                mailAttachment.setContentType('application/pdf');
                mailAttachment.setFileName('Invoice: ' + currentService.InvoiceNumberVersion__c + '.pdf');
                mailAttachment.setInline(false);
            }

            Contact contact = payment.Payee_Type__c == 'Client' ? currentService.Contact__r : currentService.Caseworker__r;
            if (contact == null || contact.Email == null) continue;

            emailCooker.addEmail(
                    infoOrgWideAddress.Id,
                    contact.Email,
                    paymentReceivedEmailTemplate.Id,
                    contact.Id,
                    payment.Id,
                    mailAttachment != null
                            ? new List<Messaging.EmailFileAttachment>{mailAttachment}
                            : null
            );
            currentService.InvoiceVersion__c = currentService.InvoiceVersion__c + 1;
            services.add(currentService);
        }

        if (emailCooker.getEmails().size() == 0) return;

        emailCooker.send();

        if (services == null || services.isEmpty()) return;
        Database.update(services);
    }

}