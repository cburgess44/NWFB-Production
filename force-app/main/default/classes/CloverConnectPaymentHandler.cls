/**
 * Created by dudunato on 15/06/22.
 */

public interface CloverConnectPaymentHandler {

    void process(Map<String, Object> requestParams, Map<String, Object> cloverConnectResponse);

}