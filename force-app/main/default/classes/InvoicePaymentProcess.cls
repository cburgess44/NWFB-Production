public with sharing class InvoicePaymentProcess implements CloverConnectPaymentHandler {


    public void process(Map<String, Object> requestParams, Map<String, Object> authorizeResponse) {
        if (!new CloverConnectClient.TransactionStatus(authorizeResponse).approved()) {
            createRejectedPayment(requestParams, authorizeResponse);
            return;
        }

        Map<String, Object> userFields = (Map<String, Object>) requestParams.get('userFields');
        String token = (String) authorizeResponse.get('account');

        Payment__c newPayment = new Payment__c(
                PaymentDate__c = Date.today(),
                PaymentAmount__c = Double.valueOf(authorizeResponse.get('amount')),
                PaymentMethod__c = 'CreditCard',
                TransactionId__c = (String) authorizeResponse.get('retref'),
                PaymentType__c = 'Payment',
                Status__c = 'Approved',
                CardLast4Digits__c = token.substring(token.length() - 4) 
        );

        if (userFields.get('serviceId') != null) {
            newPayment.Service__c = (Id) userFields.get('serviceId');
        }

        if (userFields.get('opportunityId') != null) {
            System.debug('created payment here');
            newPayment.Opportunity__c = (Id) userFields.get('opportunityId');
        }

        /*here I validate the past payer data*/
        if (userFields.get('payee') != null) {
            newPayment.Payee_Type__c = (String) userFields.get('payee');
        }

        insert newPayment;

        List<Object> invoicePayments = (List<Object>) userFields.get('invoicePayments');
        if (invoicePayments != null && !invoicePayments.isEmpty()) {
            List<ServicePayment__c> newInvoicePayments = new List<ServicePayment__c>();
            List<Payment__c> childPayments = new List<Payment__c>();

            for (Object invoicePaymentObj : invoicePayments) {
                Map<String, Object> invoicePaymentMap = (Map<String, Object>) invoicePaymentObj;

                newInvoicePayments.add(
                        new ServicePayment__c(
                                Service__c = String.valueOf(invoicePaymentMap.get('Service__c')),
                                Payment__c = newPayment.Id,
                                Amount__c = Double.valueOf(invoicePaymentMap.get('Amount__c'))
                        )
                );

                childPayments.add(new Payment__c(
                        Service__c = (Id) String.valueOf(invoicePaymentMap.get('Service__c')),
                        ParentPayment__c = newPayment.Id,
                        PaymentAmount__c = Double.valueOf(invoicePaymentMap.get('Amount__c')),
                        PaymentDate__c = newPayment.PaymentDate__c,
                        PaymentMethod__c = newPayment.PaymentMethod__c,
                        TransactionId__c = newPayment.TransactionId__c,
                        PaymentType__c = 'Payment',
                        Status__c = 'Approved',
                        CardLast4Digits__c = newPayment.CardLast4Digits__c
                ));
            }

            insert newInvoicePayments;
            insert childPayments;
        }
    }

    public void createRejectedPayment(Map<String, Object> requestParams, Map<String, Object> authorizeResponse) {
        Map<String, Object> userFields = (Map<String, Object>) requestParams.get('userFields');
        String token = (String) authorizeResponse.get('account');

        Id opportunityId = (Id) userFields.get('opportunityId');
        if (opportunityId == null) return;

        Payment__c rejectedPayment = new Payment__c(
                Opportunity__c = opportunityId,
                PaymentDate__c = Date.today(),
                PaymentAmount__c = Double.valueOf(authorizeResponse.get('amount')),
                PaymentMethod__c = 'CreditCard',
                TransactionId__c = (String) authorizeResponse.get('retref'),
                PaymentType__c = 'Payment',
                Status__c = 'Rejected',
                CardLast4Digits__c = token.substring(token.length() - 4)
        );

        insert rejectedPayment;
    }
}