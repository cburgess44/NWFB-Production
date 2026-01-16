/**
 * Created by Gustavo on 10/01/24.
 */

@IsTest
private class InvoicePaymentProcessTest {
    @IsTest
    static void process() {
        Map<String, Object> requestParams = new Map<String, Object>();
        requestParams.put('userFields', new Map<String, Object>());
        Map<String, Object> responseParams = new Map<String, Object>();
        responseParams.put('account', '42424242424242');
        responseParams.put('amount', '2');
        responseParams.put('retref', '123123123');
        responseParams.put('respstat', 'A');
        new InvoicePaymentProcess().process(requestParams, responseParams);
    }
}