public without sharing class AppointmentSelector {

    public AppointmentSelector() {
    }

    public static AppointmentSelector newInstance() {
        return new AppointmentSelector();
    }

    public Map<String, Appointment__c> getAppointmentById(Set<String> appointmentIds){
        Map<String, Appointment__c> appointmentMap = new Map<String, Appointment__c>([
                            SELECT 
                                Id,
                                Name,
                                Service__r.Contact__c,
                                Service__r.Contact__r.MobilePhone,
                                Service__r.Contact__r.Email,
                                Service__r.Contact__r.Name
                            FROM Appointment__c 
                            WHERE Id IN: appointmentIds]);

        return appointmentMap;
    }

    public Map<Id, Appointment__c> getOldestScheduledAppointmentByServiceId(Map<Id, Id> mapAppointmentServices){
        Map<Id, Appointment__c> appointmentsByServiceId = new Map<Id, Appointment__c>();

        List<Appointment__c> appointments = new List<Appointment__c>([
                        SELECT 
                            Id, Service__c, Status__c, CreatedDate
                        FROM Appointment__c 
                        WHERE Service__c IN : mapAppointmentServices.keySet() 
                        AND Status__c = 'Scheduled' 
                        AND Id NOT IN : mapAppointmentServices.values() 
                        ORDER BY CreatedDate  ASC LIMIT 1
        ]);

        for (Appointment__c appointment : appointments) {
            appointmentsByServiceId.put(appointment.Service__c, appointment);
        }

        return appointmentsByServiceId;
    }
}