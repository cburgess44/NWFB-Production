/**
 * Created by Gustavo on 11/03/24.
 */

public with sharing class RecurringPaymentCreationBatch implements Database.Batchable<SObject>, Database.AllowsCallouts {

        public Iterable<SObject> start(Database.BatchableContext context) {
            return Database.getQueryLocator([
                    SELECT  Id,
                            Name,
                            PaymentToken__c,
                            CloseDate,
                            Payment_Type__c,
                            ContactId,
                            Amount,
                            npsp__Primary_Contact__r.CloverConnectProfileId__c,
                            RecordTypeId,
                            npe03__Recurring_Donation__c
                    FROM Opportunity
                    WHERE CloseDate = TODAY
                        AND PaymentToken__c != NULL
                        AND (Payment_Type__c = 'Credit Card' OR npe03__Recurring_Donation__r.npsp__PaymentMethod__c = 'Credit Card')
                        AND StageName != 'Closed/Won'
            ]);
        }

        public void execute(Database.BatchableContext context, List<SObject> opportunities) {
            System.debug('here');
            if (opportunities.isEmpty()) return;
            new RecurringPaymentCreation().create(opportunities);
        }

        public void finish(Database.BatchableContext context) {

        }

}