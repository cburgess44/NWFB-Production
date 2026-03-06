@IsTest
private class InvoicePaymentProcessTest {

    @TestSetup
    static void setupData() {
        Contact testContact = new Contact(FirstName = 'Test', LastName = 'BulkPay');
        insert testContact;

        TriggerManagement.disableTrigger('ServiceTrigger');

        List<Service__c> services = new List<Service__c>();
        for (Integer i = 0; i < 3; i++) {
            services.add(new Service__c(
                Contact__c = testContact.Id,
                Status__c = 'Processing',
                SubType__c = 'Delivery'
            ));
        }
        insert services;

        Opportunity testOpp = new Opportunity(
            Name = 'Test Opp BulkPay',
            StageName = 'Closed Won',
            CloseDate = Date.today()
        );
        insert testOpp;
    }

    static Map<String, Object> buildApprovedResponse(Decimal amount) {
        return new Map<String, Object>{
            'account' => '42424242424242',
            'amount' => String.valueOf(amount),
            'retref' => '123123123',
            'respstat' => 'A'
        };
    }

    static Map<String, Object> buildRejectedResponse(Decimal amount) {
        return new Map<String, Object>{
            'account' => '42424242424242',
            'amount' => String.valueOf(amount),
            'retref' => '456456456',
            'respstat' => 'C'
        };
    }

    @IsTest
    static void process() {
        Map<String, Object> requestParams = new Map<String, Object>();
        requestParams.put('userFields', new Map<String, Object>());

        Test.startTest();
        new InvoicePaymentProcess().process(requestParams, buildApprovedResponse(2));
        Test.stopTest();

        List<Payment__c> payments = [SELECT Id FROM Payment__c];
        System.assertEquals(1, payments.size(), 'Should create one payment with empty userFields');
    }

    @IsTest
    static void testBulkPaymentCreatesChildPayments() {
        List<Service__c> services = [SELECT Id FROM Service__c ORDER BY CreatedDate LIMIT 2];

        List<Object> invoicePayments = new List<Object>();
        invoicePayments.add(new Map<String, Object>{
            'Service__c' => services[0].Id,
            'Amount__c' => 150.00
        });
        invoicePayments.add(new Map<String, Object>{
            'Service__c' => services[1].Id,
            'Amount__c' => 250.00
        });

        Map<String, Object> userFields = new Map<String, Object>();
        userFields.put('invoicePayments', invoicePayments);
        userFields.put('payee', 'Agency');

        Map<String, Object> requestParams = new Map<String, Object>();
        requestParams.put('userFields', userFields);

        Test.startTest();
        new InvoicePaymentProcess().process(requestParams, buildApprovedResponse(400));
        Test.stopTest();

        List<Payment__c> parentPayments = [
            SELECT Id, PaymentAmount__c, Service__c, Payee_Type__c
            FROM Payment__c
            WHERE ParentPayment__c = null
        ];
        System.assertEquals(1, parentPayments.size(), 'Should create one parent payment');
        System.assertEquals(400, parentPayments[0].PaymentAmount__c, 'Parent amount should be total');
        System.assertEquals(null, parentPayments[0].Service__c, 'Parent should not link to a service');
        System.assertEquals('Agency', parentPayments[0].Payee_Type__c, 'Payee type should be set');

        List<Payment__c> childPayments = [
            SELECT Id, PaymentAmount__c, Service__c, ParentPayment__c, PaymentMethod__c, Status__c
            FROM Payment__c
            WHERE ParentPayment__c = :parentPayments[0].Id
            ORDER BY PaymentAmount__c
        ];
        System.assertEquals(2, childPayments.size(), 'Should create two child payments');
        System.assertEquals(150, childPayments[0].PaymentAmount__c, 'First child amount');
        System.assertEquals(services[0].Id, childPayments[0].Service__c, 'First child service');
        System.assertEquals(250, childPayments[1].PaymentAmount__c, 'Second child amount');
        System.assertEquals(services[1].Id, childPayments[1].Service__c, 'Second child service');
        System.assertEquals('CreditCard', childPayments[0].PaymentMethod__c, 'Child inherits payment method');
        System.assertEquals('Approved', childPayments[0].Status__c, 'Child inherits status');

        List<ServicePayment__c> junctions = [
            SELECT Id, Service__c, Payment__c
            FROM ServicePayment__c
            WHERE Payment__c = :parentPayments[0].Id
        ];
        System.assertEquals(2, junctions.size(), 'Should create two junction records');
    }

    @IsTest
    static void testSingleServicePayment() {
        Service__c service = [SELECT Id FROM Service__c LIMIT 1];

        Map<String, Object> userFields = new Map<String, Object>();
        userFields.put('serviceId', service.Id);

        Map<String, Object> requestParams = new Map<String, Object>();
        requestParams.put('userFields', userFields);

        Test.startTest();
        new InvoicePaymentProcess().process(requestParams, buildApprovedResponse(100));
        Test.stopTest();

        List<Payment__c> payments = [
            SELECT Id, Service__c, PaymentAmount__c
            FROM Payment__c
        ];
        System.assertEquals(1, payments.size(), 'Should create one payment');
        System.assertEquals(service.Id, payments[0].Service__c, 'Should link to service');
        System.assertEquals(100, payments[0].PaymentAmount__c, 'Amount should match');
    }

    @IsTest
    static void testRejectedPayment() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Map<String, Object> userFields = new Map<String, Object>();
        userFields.put('opportunityId', opp.Id);

        Map<String, Object> requestParams = new Map<String, Object>();
        requestParams.put('userFields', userFields);

        Test.startTest();
        new InvoicePaymentProcess().process(requestParams, buildRejectedResponse(500));
        Test.stopTest();

        List<Payment__c> payments = [
            SELECT Id, Status__c, Opportunity__c, PaymentAmount__c
            FROM Payment__c
        ];
        System.assertEquals(1, payments.size(), 'Should create one rejected payment');
        System.assertEquals('Rejected', payments[0].Status__c, 'Status should be Rejected');
        System.assertEquals(opp.Id, payments[0].Opportunity__c, 'Should link to opportunity');
    }
}