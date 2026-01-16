public with sharing class GoogleMapsIntegrationApi {
    public Http http;
    public HttpRequest request;
    public HttpResponse response;

    private String apiKey;
    private String apiUrl;

    public GoogleMapsIntegrationApi() {
        this.setAPISettings();
        this.initHttp('GET');
    }

    private void setAPISettings() {
        GoogleMapsApiSetting__mdt mapsSettings = [
                SELECT Url__c, Key__c FROM GoogleMapsApiSetting__mdt LIMIT 1
        ];
        this.apiKey = mapsSettings.Key__c;
        this.apiUrl = mapsSettings.Url__c;
    }

    private void initHttp(String method) {
        this.http = new Http();
        this.request = new HttpRequest();
        this.request.setMethod(method);

    }

    public Map<String, Object> makeRequest(){
        this.response = this.http.send(this.request);

        if (this.response.getStatusCode() == 200) {
            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());

            if(((List<Object>) data.get('routes')).size() > 0) {
                return (Map<String, Object>) ((List<Object>) data.get('routes'))[0];
            } else {
                return new Map<String, Object>();
            }
        }

        throw new GoogleMapsApiException('No successfully response from integration');
    }

    public Map<String, Object> getRoute(String origin, List<Stop__c> stops){
        String googleMapsUrl = GoogleMapsAPIController.buildGetDirectionsURL(stops, origin);
        this.request.setEndpoint(googleMapsUrl);
        return makeRequest();
    }
    
    public with sharing class GoogleMapsApiException extends Exception {
    }
}