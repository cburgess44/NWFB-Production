public with sharing class DuplicateReviewController {
    
    @AuraEnabled(cacheable=true)
    public static List<Service__c> getMatchingServices(Id serviceId) {
        // Get the current service
        Service__c currentService = [
            SELECT Id, Address__c, City__c, Zip__c 
            FROM Service__c 
            WHERE Id = :serviceId 
            LIMIT 1
        ];
        
        if (currentService.Address__c == null || currentService.City__c == null || currentService.Zip__c == null) {
            return new List<Service__c>();
        }
        
        // Extract street number from address (everything before first space)
        String streetNumber = '';
        if (currentService.Address__c.contains(' ')) {
            streetNumber = currentService.Address__c.substringBefore(' ').trim();
        } else {
            streetNumber = currentService.Address__c.trim();
        }
        
        if (String.isBlank(streetNumber)) {
            return new List<Service__c>();
        }
        
        // Query for all matching services in same city/zip within the last 12 months
        Date twelveMonthsAgo = Date.today().addMonths(-12);
        List<Service__c> allServicesInArea = [
            SELECT Id, Name, Address__c, City__c, State__c, Zip__c, 
                   Contact__r.Name, CreatedDate, Status__c
            FROM Service__c
            WHERE Id != :serviceId
            AND RecordType.DeveloperName = 'ClientRequest'
            AND City__c = :currentService.City__c
            AND Zip__c = :currentService.Zip__c
            AND Status__c != 'Cancelled'
            AND CreatedDate >= :twelveMonthsAgo
            ORDER BY CreatedDate DESC
            LIMIT 100
        ];
        
        // Filter to only those with matching street number
        List<Service__c> matchingServices = new List<Service__c>();
        for (Service__c svc : allServicesInArea) {
            if (svc.Address__c != null) {
                String svcStreetNumber = '';
                if (svc.Address__c.contains(' ')) {
                    svcStreetNumber = svc.Address__c.substringBefore(' ').trim();
                } else {
                    svcStreetNumber = svc.Address__c.trim();
                }
                
                if (svcStreetNumber.equalsIgnoreCase(streetNumber)) {
                    matchingServices.add(svc);
                }
            }
        }
        
        return matchingServices;
    }
}
