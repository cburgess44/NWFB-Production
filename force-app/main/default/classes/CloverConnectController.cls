/**
 * Created by dudunato on 22/05/22.
 */

public with sharing class CloverConnectController {

    private static CloverConnectService service;

    static {
        service = CloverConnectService.getInstance();
    }

    @AuraEnabled
    public static Map<String, Object> authorize(String authorizeJSON, String billingPlanJSON) {
        return service.authorize(authorizeJSON, billingPlanJSON);
    }

    @AuraEnabled
    public static Object getProfile(String profileId, String merchId) {
        return service.getProfile(profileId, merchId);
    }

    @AuraEnabled
    public static Object saveProfile(String profileJSON) {
        return service.saveProfile(profileJSON);
    }

    @AuraEnabled
    public static Object deleteProfile(String profileId, String accountId, String merchId) {
        return service.deleteProfile(profileId, accountId, merchId);
    }

    @AuraEnabled
    public static Map<String, Object> refund(String refundJSON) {
        return service.refund(refundJSON);
    }

    @AuraEnabled
    public static String getMerchantId(String settingDeveloperName) {
        return service.getMerchantId(settingDeveloperName);
    }
}