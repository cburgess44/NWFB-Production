/**
 * Created by dudunato on 18/05/22.
 */

public with sharing class CloverConnectClient {

    private BasicHttp http;
    private static final String GATEWAY_PATH;

    static {
        GATEWAY_PATH = '/cardconnect/rest';
    }

    public CloverConnectClient() {
        this.http = new BasicHttp('callout:CloverConnectAPI');
    }

    public Map<String, Object> authorize(String authorizeJSON) {
        return this.http.post(GATEWAY_PATH + '/auth', authorizeJSON);
    }

    public Map<String, Object> saveProfile(String profileJSON) {
        return this.http.post(GATEWAY_PATH + '/profile', profileJSON);
    }

    public Object getProfile(String profileId, String merchId) {
        String pathURL = String.format(
                '{0}/profile/{1}//{2}',
                new String[]{
                        GATEWAY_PATH, profileId, merchId
                }
        );

        return this.http.get(pathURL);
    }

    public Object deleteProfile(String profileId, String accountId, String merchId) {
        String pathURL = String.format(
                '{0}/profile/{1}/{2}/{3}',
                new String[]{
                        GATEWAY_PATH, profileId, accountId, merchId
                }
        );

        return this.http.del(pathURL);
    }

    public Map<String, Object> refund(String refundJSON) {
        return this.http.post(GATEWAY_PATH + '/refund', refundJSON);
    }

    public Object funding(String merchId, String yyyyMMdd) {
        String pathURL = String.format(
                '{0}/funding?merchid={1}&date={2}',
                new String[]{
                        GATEWAY_PATH, merchId, yyyyMMdd
                }
        );

        return this.http.get(pathURL);
    }

    public class TransactionStatus {

        String APPROVED = 'A';
        String PROCESSED = 'Processed';
        Map<String, Object> response;

        public TransactionStatus(Map<String, Object> response) {
            this.response = response;
        }

        public Boolean approved() {
           return this.response.containsKey('respstat') && this.response.get('respstat') == APPROVED;
        }

        public Boolean processed() {
            return this.response.containsKey('status') && this.response.get('status') == PROCESSED;
        }


    }

}