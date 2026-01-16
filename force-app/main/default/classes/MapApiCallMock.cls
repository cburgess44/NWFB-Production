@isTest
global with sharing class MapApiCallMock implements HttpCalloutMock{
    
    global HttpResponse respond(HTTPRequest request){
        HttpResponse response = new HttpResponse();
        response.setStatus('200');
        response.setStatusCode(200);
        String ret = '{"routes":[]}';
        response.setBody(ret);
        return response;
    }

}