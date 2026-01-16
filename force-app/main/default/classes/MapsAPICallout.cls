public with sharing class MapsAPICallout {
    @AuraEnabled
    public static String callMapDirections(String url) {
        try {
            HttpRequest req = new HttpRequest();
            req.setHeader('Content-Type', 'application/json; charset=UTF-8');
            req.setEndpoint(url);
            req.setMethod('GET');
            Http http = new Http();
            HttpResponse res = http.send(req);
            return res.getBody();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}