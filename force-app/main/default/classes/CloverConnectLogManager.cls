/**
 * Created by dudunato on 19/06/22.
 */

public with sharing class CloverConnectLogManager implements Queueable {

    @TestVisible
    private static CloverConnectLogManager mock;
    public static final String STATUS_ATTEMPT = 'Attempt';
    public static final String STATUS_SUCCESS = 'Success';
    public static final String STATUS_FAILURE = 'Failure';

    private List<LogParam> payloads;
    private String currentService;

    public CloverConnectLogManager() {
        this.payloads = new List<LogParam>();
    }

    public static CloverConnectLogManager getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new CloverConnectLogManager();
        }
    }

    public void execute(QueueableContext context) {
        saveLogs();
    }

    private void saveLogs() {

        for (LogParam param : payloads) {
            insert new CloverConnectLog__c(
                    Service__c = currentService,
                    Payload__c = param.payload,
                    Status__c = param.status,
                    ErrorMessage__c = param.errorMessage
            );
        }

    }

    public void setCurrentService(String service) {
        this.currentService = service;
    }

    public void add(Map<String, Object> payload) {
        if (payload == null) {
            this.add('null response', STATUS_FAILURE);
            return;
        }

        if (payload.containsKey('errors') || payload.get('respstat') != 'A') {
            this.add(
                    JSON.serialize(payload),
                    STATUS_FAILURE,
                    payload.containsKey('errors')
                        ? JSON.serialize(payload.get('errors'))
                        : (String) payload.get('resptext')
            );
        } else {
            this.add(
                    JSON.serialize(payload),
                    STATUS_SUCCESS
            );
        }
    }

    public void add(String payload, String status) {
        this.payloads.add(new LogParam(payload, status));
    }

    public void add(String payload, String status, String errorMessage) {
        this.payloads.add(new LogParam(payload, status, errorMessage));
    }

    public void queueUp() {
        System.enqueueJob(this);
    }

    private class LogParam {

        private String payload;
        private String status;
        private String errorMessage;

        LogParam(String payload, String status) {
            this.payload = payload;
            this.status = status;
            this.errorMessage = null;
        }

        LogParam(String payload, String status, String errorMessage) {
            this.payload = payload;
            this.status = status;
            this.errorMessage = errorMessage;
        }


    }

}