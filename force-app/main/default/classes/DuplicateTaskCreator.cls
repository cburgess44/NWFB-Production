public with sharing class DuplicateTaskCreator implements Queueable {
    
    private Id serviceId;
    private String serviceName;
    private String serviceAddress;
    
    public DuplicateTaskCreator(Id serviceId, String serviceName, String serviceAddress) {
        this.serviceId = serviceId;
        this.serviceName = serviceName;
        this.serviceAddress = serviceAddress;
    }
    
    public void execute(QueueableContext context) {
        // Get Sara Tedder's User ID (Client Service Manager)
        Id ownerId = '005A0000004v1L9IAI';
        
        Task t = new Task();
        t.OwnerId = ownerId;
        t.WhatId = serviceId;
        t.Subject = 'Potential Duplicate - Review Required';
        t.Status = 'Not Started';
        t.Priority = 'High';
        t.Type = 'Other';
        t.ActivityDate = Date.today();
        t.Description = 'This service request has been flagged as a potential duplicate.\n\n' +
                        'Service: ' + serviceName + '\n' +
                        'Address: ' + serviceAddress + '\n\n' +
                        'Please review and clear the duplicate flag if this is a legitimate separate request.';
        
        insert t;
    }
    
    @InvocableMethod(label='Create Duplicate Review Task' description='Creates a Task for duplicate review asynchronously')
    public static void createTaskAsync(List<TaskRequest> requests) {
        for (TaskRequest req : requests) {
            System.enqueueJob(new DuplicateTaskCreator(req.serviceId, req.serviceName, req.serviceAddress));
        }
    }
    
    public class TaskRequest {
        @InvocableVariable(label='Service Record ID' required=true)
        public Id serviceId;
        
        @InvocableVariable(label='Service Name' required=true)
        public String serviceName;
        
        @InvocableVariable(label='Service Address' required=true)
        public String serviceAddress;
    }
}
