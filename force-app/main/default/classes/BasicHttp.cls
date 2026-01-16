/**
 * Created by dudunato on 18/05/22.
 */

public with sharing class BasicHttp {

    public static final String GET_METHOD = 'GET';
    public static final String DELETE_METHOD = 'DELETE';

    private Http http;
    private String currentEndpoint;
    private Map<String, String> extraHeaders;

    public BasicHttp(String currentEndpoint) {
        this.http = new Http();
        this.currentEndpoint = currentEndpoint;
        this.extraHeaders = new Map<String, String>();
    }

    public void addHeader(String key, String value) {
        this.extraHeaders.put(key, value);
    }

    public Object get(String pathURL) {
        return this.getOrDelete(pathURL, GET_METHOD);
    }

    public Object del(String pathURL) {
        return this.getOrDelete(pathURL, DELETE_METHOD);
    }

    public Object getOrDelete(String pathURL, String method) {
        HttpRequest request = new HttpRequest();

        request.setEndpoint(this.currentEndpoint + pathURL);
        request.setMethod(method);
        populateExtraHeaders(request);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');

        Object responseData = null;

        try {

            HttpResponse response = this.http.send(request);

            if (response.getStatusCode() == 200) {

                if (response.getBody().startsWith('[')) {
                    responseData = (List<Object>) JSON.deserializeUntyped(response.getBody());
                } else {
                    responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                }

                return responseData;
            }

            this.buildErrorResponseGET(responseData, response);
        } catch (Exception e) {
            this.buildErrorResponseGET(responseData, e.getMessage());
        }

        return responseData;
    }

    public Map<String, Object> post(String pathURL, String postParams) {
        return post(pathURL, postParams, 'json');
    }

    public Map<String, Object> post(String pathURL, String postParams, String contentType) {

        HttpRequest request = new HttpRequest();

        request.setEndpoint(this.currentEndpoint + pathURL);
        request.setMethod('POST');
        populateExtraHeaders(request);
        request.setHeader('Content-Type', 'application/' + contentType + ';charset=UTF-8');
        request.setBody(
                contentType.contains('form')
                        ? toFormParameters(postParams)
                        : postParams
        );


        Map<String, Object> responseData = new Map<String, Object>();

        try {

            HttpResponse response = this.http.send(request);

            if (response.getStatusCode() == 200 || response.getStatusCode() == 201) {
                responseData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                return responseData;
            }

            this.buildErrorResponse(responseData, response);

        } catch (Exception e) {
            this.buildErrorResponse(responseData, e.getMessage());
        }

        return responseData;
    }

    private void populateExtraHeaders(HttpRequest request) {
        for (String key : this.extraHeaders.keySet()) request.setHeader(key, this.extraHeaders.get(key));
    }

    private static String toFormParameters(String stringParams) {
        Map<String, Object> params = (Map<String, Object>) JSON.deserializeUntyped(stringParams);

        String result = '';

        for (String paramKey : params.keySet()) {
            String paramValue = (String) params.get(paramKey);
            result += EncodingUtil.urlEncode(paramKey, 'UTF-8') + '=' + EncodingUtil.urlEncode(paramValue, 'UTF-8') + '&';
        }

        return result.removeEnd('&');
    }

    private void buildErrorResponseGET(Object genericResponseData, Object rawData) {
        if (genericResponseData == null) genericResponseData = new Map<String, Object>();
        this.buildErrorResponse((Map<String, Object>) genericResponseData, rawData);
    }

    private void buildErrorResponse(Map<String, Object> responseData, Object rawData) {

        if (rawData instanceof HttpResponse) {
            HttpResponse response = (HttpResponse) rawData;

            responseData.put(
                    'errors',
                    new Map<String, Object>{
                            'message' => response.getBody(),
                            'statusCode' => response.getStatusCode()
                    }
            );
        }

        if (rawData instanceof String) {
            String message = (String) rawData;

            responseData.put(
                    'errors',
                    new Map<String, Object>{
                            'message' => message
                    }
            );
        }

    }


}