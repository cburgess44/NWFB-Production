@isTest
global with sharing class AppointmentMock implements HttpCalloutMock{
    
    global HttpResponse respond(HTTPRequest request){
        HttpResponse response = new HttpResponse();
        response.setStatus('201');
        response.setStatusCode(201);
        response.setBody('Message sent!');
        return response;
    }

}