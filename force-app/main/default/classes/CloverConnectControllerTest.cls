/**
 * Created by Gustavo on 08/01/24.
 */

@IsTest
private class CloverConnectControllerTest {
    @IsTest
    static void authorize() {
        System.assert(CloverConnectController.authorize('', '') != null);
    }

//    @IsTest
//    static void getProfile() {
//        System.assert(CloverConnectController.getProfile('', '') != null);
//    }

    @IsTest
    static void saveProfile() {
        System.assert(CloverConnectController.saveProfile('') != null);
    }
//
//    @IsTest
//    static void deleteProfile() {
//        System.assert(CloverConnectController.deleteProfile('', '', '') != null);
//    }

    @IsTest
    static void refund() {
        System.assert(CloverConnectController.refund('') != null);
    }

//    @IsTest
//    static void getMerchantId() {
//        System.assert(CloverConnectController.getMerchantId('') != null);
//    }
}