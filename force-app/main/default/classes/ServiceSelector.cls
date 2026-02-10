public without sharing class ServiceSelector {
    private static ServiceSelector instance = null;

    public static ServiceSelector getInstance() {
        if (instance == null) {
            instance = new ServiceSelector();
        }
        return instance;
    }

    public List<Service__c> getServiceByIds(Set<Id> serviceIds){
        return [
                SELECT
                        Id,
                        Name,
                        Delivery_Type__c,
                        Delivery_Fee__c,
                        Processing_Fee__c,
                        Pickup_Fee__c,
                        OverrideFeeCalculation__c,
                        Date__c,
                        InvoiceVersion__c,
                        InvoiceNumberVersion__c,
                        Invoice_Number__c,
                        Status__c,
                        Area__c,
                        Stop__c,
                        Zip__c,
                        Contact__c,
                        Location__c,
                        OwnerId,
                        Trip__c,
                        EmailAttempts__c,
                        OutgoingSMSAttempts__c,
                        LogCallAttempts__c,
                        RequestAmount__c,
                        CurrentAppointment__c,
                        RecordTypeName__c,
                        RecordType.DeveloperName,
                        Contact__r.FirstName,
                        Contact__r.Name,
                        Contact__r.MobilePhone,
                        Contact__r.Email,
                        Contact__r.LocationNew__c,
                        CreatedDate,
                        Area__r.Street__c,
                        Area__r.ZipCode__c,
                        Area__r.Name,
                        Contact__r.npe01__Preferred_Email__c,
                        Contact__r.npe01__HomeEmail__c,
                        Contact__r.npe01__AlternateEmail__c,
                        Contact__r.npe01__WorkEmail__c,
                        Caseworker__r.Email,
                        CaseWorker__r.npe01__Preferred_Email__c,
                        CaseWorker__r.npe01__HomeEmail__c,
                        CaseWorker__r.npe01__AlternateEmail__c,
                        CaseWorker__r.npe01__WorkEmail__c,
                        Caseworker__r.AP_Contact_Email__c,
                        Agency__c,
                        Area__r.PhysicalAddress__c,
                        Area__r.Timeframe__c,
                        Stop__r.Trip__c,
                        Stop__r.Trip__r.Status__c,
                        Location__r.Name,
                        Location__r.Address__c,
                        Location__r.TwilioPhoneNumber__c,
                        Location__r.RedirectPhoneNumber__c,
                        Location__r.City__c,
                        CurrentAppointment__r.Status__c,
                        Total_Items__c,
                        SubType__c,
                        RecordTypeId,
                        Agency__r.Name,
                        (SELECT Id, Name, Quantity__c, Product__r.Name FROM ServiceItems__r)
                FROM Service__c
                WHERE Id IN :serviceIds
        ];
    }

    public List<Service__c> getServiceByIdsAndItemsByCategory(Set<Id> serviceIds){
        return [
                SELECT
                        Id,
                        Delivery_Type__c,
                        Delivery_Fee__c,
                        OverrideFeeCalculation__c,
                        Date__c,
                        Caseworker__c,
                        Status__c,
                        Area__c,
                        Stop__c,
                        Zip__c,
                        Contact__c,
                        Location__c,
                        EmailAttempts__c,
                        OutgoingSMSAttempts__c,
                        LogCallAttempts__c,
                        RequestAmount__c,
                        CurrentAppointment__c,
                        CurrentAppointment__r.Status__c,
                        RecordType.DeveloperName,
                        Contact__r.Name,
                        Contact__r.MobilePhone,
                        Contact__r.Email,
                        Contact__r.npe01__Preferred_Email__c,
                        Contact__r.npe01__HomeEmail__c,
                        Contact__r.npe01__AlternateEmail__c,
                        Contact__r.npe01__WorkEmail__c,
                        CreatedDate,
                        Area__r.Street__c,
                        Area__r.ZipCode__c,
                        Area__r.Name,
                        Area__r.PhysicalAddress__c,
                        Area__r.Timeframe__c,
                        Stop__r.Trip__c,
                        Stop__r.Trip__r.Status__c,
                        Location__r.Name,
                        Location__r.Address__c,
                        Location__r.TwilioPhoneNumber__c,
                        Location__r.RedirectPhoneNumber__c,
                        Owner.Email,
                        OwnerId,
                        (SELECT Id, Name FROM ServiceItems__r WHERE Product__r.Category__c = 'Mattresses' AND Product__r.Invoiceable__c = TRUE)
                FROM Service__c
                WHERE Id IN :serviceIds
        ];
    }

    public List<Service__c> getServicesByStopsIds(Set<Id> stopIds){
        return [
                SELECT
                        Id,
                        Delivery_Type__c,
                        Delivery_Fee__c,
                        OverrideFeeCalculation__c,
                        Date__c,
                        Status__c,
                        Name,
                        Area__c,
                        Stop__c,
                        Zip__c,
                        Contact__c,
                        Location__c,
                        OwnerId,
                        EmailAttempts__c,
                        OutgoingSMSAttempts__c,
                        LogCallAttempts__c,
                        RequestAmount__c,
                        CurrentAppointment__c,
                        CurrentAppointment__r.Status__c,
                        Area__r.ZipCode__c,
                        Area__r.Street__c,
                        Area__r.PhysicalAddress__c,
                        Area__r.Name,
                        Area__r.Timeframe__c,
                        Contact__r.Name,
                        Stop__r.Trip__c,
                        Stop__r.Trip__r.Status__c,
                        (SELECT Id, Name FROM ServiceItems__r)
                FROM Service__c
                WHERE Stop__c IN :stopIds
        ];
    }


    public List<Service__c> getServicesByDate(Date serviceDate){
        return [
                SELECT
                        Id,
                        Delivery_Type__c,
                        Delivery_Fee__c,
                        OverrideFeeCalculation__c,
                        Date__c,
                        Status__c,
                        Area__c,
                        Stop__c,
                        Zip__c,
                        Contact__c,
                        Location__c,
                        OwnerId,
                        EmailAttempts__c,
                        OutgoingSMSAttempts__c,
                        LogCallAttempts__c,
                        RequestAmount__c,
                        CurrentAppointment__c,
                        CurrentAppointment__r.Status__c,
                        Area__r.ZipCode__c,
                        Area__r.Street__c,
                        Area__r.PhysicalAddress__c,
                        Area__r.Name,
                        Area__r.Timeframe__c,
                        Contact__r.Name,
                        Stop__r.Trip__c,
                        Stop__r.Trip__r.Status__c,
                        (SELECT Id, Name FROM ServiceItems__r)
                FROM Service__c
                WHERE Date__c = :serviceDate
        ];
    }

    public List<Service__c> getServicesByContactId(Set<Id> contactIds){
        return [
                SELECT
                        Id,
                        Delivery_Type__c,
                        Delivery_Fee__c,
                        OverrideFeeCalculation__c,
                        Date__c,
                        Status__c,
                        Area__c,
                        Stop__c,
                        Zip__c,
                        Contact__c,
                        Location__c,
                        OwnerId,
                        EmailAttempts__c,
                        OutgoingSMSAttempts__c,
                        LogCallAttempts__c,
                        RequestAmount__c,
                        CurrentAppointment__c,
                        CurrentAppointment__r.Status__c,
                        Area__r.ZipCode__c,
                        Area__r.Street__c,
                        Area__r.PhysicalAddress__c,
                        Area__r.Name,
                        Area__r.Timeframe__c,
                        Contact__r.Name,
                        Stop__r.Trip__c,
                        Stop__r.Trip__r.Status__c,
                        RecordTypeId,
                        SubType__c,
                        Agency__r.Name,
                        Contact__r.FirstName,
                        Contact__r.LastName,
                        (SELECT Id, Name FROM ServiceItems__r)
                FROM Service__c
                WHERE Contact__c IN :contactIds
                ORDER BY CreatedDate DESC
        ];
    }

    public List<Service__c> getServiceByContactIdAndDate(Set<Id> contactIds){
        return [
                SELECT
                        Id,
                        Delivery_Type__c,
                        Delivery_Fee__c,
                        OverrideFeeCalculation__c,
                        Date__c,
                        Status__c,
                        Area__c,
                        Stop__c,
                        Zip__c,
                        Contact__c,
                        Location__c,
                        OwnerId,
                        EmailAttempts__c,
                        OutgoingSMSAttempts__c,
                        LogCallAttempts__c,
                        RequestAmount__c,
                        CurrentAppointment__c,
                        CurrentAppointment__r.Status__c
                FROM Service__c
                WHERE Contact__c  IN :contactIds AND CreatedDate = LAST_N_MONTHS:12
        ];
    }

    public List<Service__c> getClientRequestServicesById(Set<Id> ids){
        return [
                SELECT
                        Id,
                        Delivery_Type__c,
                        Delivery_Fee__c,
                        OverrideFeeCalculation__c,
                        Date__c,
                        Status__c,
                        Area__c,
                        Stop__c,
                        Zip__c,
                        Contact__c,
                        Location__c,
                        OwnerId,
                        EmailAttempts__c,
                        OutgoingSMSAttempts__c,
                        LogCallAttempts__c,
                        RequestAmount__c,
                        CurrentAppointment__c,
                        CurrentAppointment__r.Status__c
                FROM Service__c
                WHERE Id IN :ids AND RecordType.DeveloperName = 'ClientRequest'
        ];
    }

    public List<Service__c> getServiceByAndLastPayment(Set<Id> ids){
        return [
                SELECT
                        Id,
                        Delivery_Type__c,
                        Delivery_Fee__c,
                        OverrideFeeCalculation__c,
                        Date__c,
                        Status__c,
                        Area__c,
                        Stop__c,
                        Contact__c,
                        Location__c,
                        (SELECT Id FROM Payments__r ORDER BY CreatedDate DESC LIMIT 1)
                FROM Service__c 
                WHERE Id IN :ids
        ];
    }

    public Map<Id, Service__c> getServicesRecordTypesById(Set<Id> servicesIds){
        return new Map<Id, Service__c>([SELECT Id, RecordType.DeveloperName FROM Service__c WHERE Id IN: servicesIds]);
    }

    /**
     * Returns existing Client Request services in the same city/zip as the given records (last 12 months, not cancelled).
     * Used for duplicate address detection with one SOQL per batch instead of per record.
     */
    public List<Service__c> getPotentialDuplicateServicesByCityZip(Set<Id> excludeIds, List<Service__c> newRecords) {
        if (newRecords == null || newRecords.isEmpty()) {
            return new List<Service__c>();
        }
        Set<String> cityZipSeen = new Set<String>();
        List<String> cityZipConditions = new List<String>();
        for (Service__c s : newRecords) {
            if (String.isBlank(s.City__c) || String.isBlank(s.Zip__c)) continue;
            String key = s.City__c + '|' + s.Zip__c;
            if (cityZipSeen.contains(key)) continue;
            cityZipSeen.add(key);
            String city = String.escapeSingleQuotes(s.City__c.trim());
            String zip = String.escapeSingleQuotes(s.Zip__c.trim());
            cityZipConditions.add('(City__c = \'' + city + '\' AND Zip__c = \'' + zip + '\')');
        }
        if (cityZipConditions.isEmpty()) {
            return new List<Service__c>();
        }
        List<String> excludeIdStrs = new List<String>();
        for (Id i : excludeIds) {
            excludeIdStrs.add('\'' + String.escapeSingleQuotes(String.valueOf(i)) + '\'');
        }
        String excludeClause = excludeIdStrs.isEmpty() ? '' : ' AND Id NOT IN (' + String.join(excludeIdStrs, ',') + ')';
        String cityZipFilter = String.join(cityZipConditions, ' OR ');
        String soql = 'SELECT Id, Name, Address__c, City__c, Zip__c FROM Service__c' +
                ' WHERE RecordType.DeveloperName = \'ClientRequest\'' +
                ' AND Status__c != \'Cancelled\'' +
                ' AND CreatedDate = LAST_N_MONTHS:12' +
                excludeClause +
                ' AND (' + cityZipFilter + ')';
        return (List<Service__c>) Database.query(soql);
    }

}