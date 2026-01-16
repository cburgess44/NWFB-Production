/**
 * Created by dudunato on 03/06/22.
 */

public with sharing class CloverConnectSettingsSelector {

    @TestVisible
    private static CloverConnectSettingsSelector mock;
    public static final String HANDLER_TYPE_AUTHORIZE = 'Authorize';

    public static CloverConnectSettingsSelector getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new CloverConnectSettingsSelector();
        }
    }

    public String getMerchantId(String settingDeveloperName) {
        CloverConnectMerchantSetting__mdt currentMerchantSetting = CloverConnectMerchantSetting__mdt.getInstance(
                settingDeveloperName
        );

        if (currentMerchantSetting == null || !currentMerchantSetting.Active__c) {
            throw new CloverConnectException('No merchant setting found!');
        }

        return currentMerchantSetting.MerchantId__c;
    }

    public List<CloverConnectPaymentHandler__mdt> getHandlersByType(String type) {

        return [
                SELECT ClassName__c
                FROM CloverConnectPaymentHandler__mdt
                WHERE HandlerType__c = :type
                  AND Active__c = TRUE
        ];
    }



}