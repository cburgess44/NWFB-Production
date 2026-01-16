/**
 * Created by dudunato on 18/06/22.
 */

public with sharing class CloverConnectPaymentManager {

    private static CloverConnectPaymentManager mock;
    private CloverConnectSettingsSelector settingsSelector;

    private CloverConnectPaymentManager(CloverConnectSettingsSelector settingsSelector) {
        this.settingsSelector = settingsSelector;
    }

    public static CloverConnectPaymentManager getInstance(CloverConnectSettingsSelector settingsSelector) {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new CloverConnectPaymentManager(settingsSelector);
        }
    }

    public void callHandlers(Map<String, Object> authorizationResponse, String handlerType) {
        callHandlers(null, authorizationResponse, handlerType);
    }

    public void callHandlers(Map<String, Object> requestParams, Map<String, Object> authorizationResponse, String handlerType) {
        if (authorizationResponse == null || authorizationResponse.containsKey('errors')) return;

        List<CloverConnectPaymentHandler__mdt> paymentHandlers = this.settingsSelector.getHandlersByType(
                handlerType
        );

        if (paymentHandlers.isEmpty()) return;

        for (CloverConnectPaymentHandler__mdt paymentHandler : paymentHandlers) {
            Type handlerTypeClass = Type.forName(paymentHandler.ClassName__c);
            CloverConnectPaymentHandler iHandler = (CloverConnectPaymentHandler) handlerTypeClass.newInstance();
            iHandler.process(requestParams, authorizationResponse);
        }

    }

}