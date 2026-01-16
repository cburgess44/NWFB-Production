/**
 * Created by dudunato on 22/05/22.
 */

public with sharing class CloverConnectService {

    @TestVisible
    private static CloverConnectService mock;

    @TestVisible
    private CloverConnectClient client;
    @TestVisible
    private CloverConnectSettingsSelector settingsSelector;
    @TestVisible
    private CloverConnectLogManager logManager;

    public CloverConnectService() {
        this.client = new CloverConnectClient();
        this.settingsSelector = CloverConnectSettingsSelector.getInstance();
        this.logManager = CloverConnectLogManager.getInstance();
    }

    public static CloverConnectService getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new CloverConnectService();
        }
    }

    public Map<String, Object> authorize(String authorizeJSON, String billingPlanJSON) {
        logManager.setCurrentService(CloverConnectSettingsSelector.HANDLER_TYPE_AUTHORIZE);

        Map<String, Object> authResponse = null;

        try {

            logManager.add(authorizeJSON, CloverConnectLogManager.STATUS_ATTEMPT);
            authResponse = this.client.authorize(authorizeJSON);

            logManager.add(authResponse);

            CloverConnectPaymentManager.getInstance(settingsSelector).callHandlers(
                    consolidateRequestParams(authorizeJSON, billingPlanJSON),
                    authResponse,
                    CloverConnectSettingsSelector.HANDLER_TYPE_AUTHORIZE
            );

        } catch (Exception e) {
            logManager.add(authorizeJSON, CloverConnectLogManager.STATUS_FAILURE, e.getMessage());
        }

        logManager.queueUp();

        return authResponse;
    }

    private static Map<String, Object> consolidateRequestParams(String authorizeJSON, String billingPlanJSON) {
        Map<String, Object> requestParams = (Map<String, Object>) JSON.deserializeUntyped(authorizeJSON);

        if (billingPlanJSON != null) {
            requestParams.putAll((Map<String, Object>) JSON.deserializeUntyped(billingPlanJSON));
        }

        return requestParams;
    }

    public Object getProfile(String profileId, String merchId) {
        Object getResponse = this.client.getProfile(profileId, merchId);
        return getResponse;
    }

    public Map<String, Object> saveProfile(String profileJSON) {
        Map<String, Object> saveResponse = this.client.saveProfile(profileJSON);
        return saveResponse;
    }

    public Object deleteProfile(String profileId, String accountId, String merchId) {
        Object deleteResponse = this.client.deleteProfile(profileId, accountId, merchId);
        return deleteResponse;
    }

    public Map<String, Object> refund(String refundJSON) {
        return this.client.refund(refundJSON);
    }

    public String getMerchantId(String settingDeveloperName) {
        return this.settingsSelector.getMerchantId(settingDeveloperName);
    }

}