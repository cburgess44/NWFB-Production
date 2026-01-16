/**
 * Created by Gustavo on 10/01/24.
 */

@IsTest
private class CloverConnectSettingsSelectorTest {
    @IsTest
    static void getMerchantId() {
        String merchantId = CloverConnectSettingsSelector.getInstance().getMerchantId('MerchantSetting');
        System.assert(merchantId != null);
    }

    @IsTest
    static void getHandlersByType() {
        List<CloverConnectPaymentHandler__mdt> handlers = CloverConnectSettingsSelector.getInstance().getHandlersByType(
                CloverConnectSettingsSelector.HANDLER_TYPE_AUTHORIZE
        );

        System.assert(!handlers.isEmpty());
    }
}