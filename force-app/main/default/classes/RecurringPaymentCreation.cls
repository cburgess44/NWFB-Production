/**
 * Created by Gustavo on 11/03/24.
 */

public with sharing class RecurringPaymentCreation {

    public void create(List<Opportunity> opportunities) {
        Date today = Date.today();
        String merchId = CloverConnectService.getInstance().getMerchantId('MerchantSetting');
        List<Opportunity> oppsToupdate = new List<Opportunity>();
        List<npe03__Recurring_Donation__c> recurringDonationsToUpdate = new List<npe03__Recurring_Donation__c>();
        for (Opportunity opp : opportunities) {

            if (opp.PaymentToken__c == null) continue;
            if (opp.CloseDate != today) continue;
            if (opp.Payment_Type__c != 'Credit Card') continue;

            List<Object> savedMethods = (List<Object>) CloverConnectService.getInstance().getProfile(
                    opp.npsp__Primary_Contact__r.CloverConnectProfileId__c,
                    merchId
            );

            Map<String, Object> chargeRequest = new Map<String, Object>();
            for (Object obj : savedMethods) {
                Map<String, Object> savedMethod = (Map<String, Object>) obj;

                String savedMethodToken = (String) savedMethod.get('token');

                if (savedMethodToken != opp.PaymentToken__c) continue;
                chargeRequest.put('name', (String) savedMethod.get('name'));
                chargeRequest.put('expiry', (String) savedMethod.get('expiry'));
            }

            Map<String, String> userFields = new Map<String, String>{
                    'opportunityId' => opp.Id,
                    'contactId' => opp.ContactId

            };

            chargeRequest.put('amount', String.valueOf(opp.Amount));
            chargeRequest.put('account', opp.PaymentToken__c);
            chargeRequest.put('merchid', merchId);
            chargeRequest.put('capture', 'Y');
            chargeRequest.put('userFields', userFields);
            System.debug('chargeRequest ' + chargeRequest);
            Map<String, Object> ret = CloverConnectService.getInstance().authorize(
                    JSON.serialize(chargeRequest),
                    null
            );
            System.debug('ret ' + ret);

            // Only mark as Closed/Won if payment was approved
            if (ret != null && new CloverConnectClient.TransactionStatus(ret).approved()) {
                opp.StageName = 'Closed/Won';
                opp.Paid_Amount__c = opp.Amount;
                oppsToupdate.add(opp);
                npe03__Recurring_Donation__c recurringDonation = new npe03__Recurring_Donation__c(Id = opp.npe03__Recurring_Donation__c, npe03__Last_Payment_Date__c = today);
                recurringDonationsToUpdate.add(recurringDonation);
            } else {
                System.debug('Payment declined for Opportunity: ' + opp.Id + ' - Response: ' + ret);
            }

        }
        System.debug('heer');
        update oppsToupdate;
        update recurringDonationsToUpdate;
    }

}