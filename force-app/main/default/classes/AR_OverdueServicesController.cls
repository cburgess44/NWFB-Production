/**
 * Controller for the AR Overdue Services LWC
 * Fetches services with outstanding balances for display in an interactive table
 * 
 * =====================================================================================
 * SERVICE DATE FALLBACK LOGIC (Added Jan 2026)
 * =====================================================================================
 * 
 * PROBLEM: 
 * Some completed services have no ServiceRenderedDate__c because they never went 
 * through the "Close Trip" flow (which is the only process that sets this field).
 * This causes them to appear as "No Service Date" in AR aging, making them hard to action.
 * 
 * ROOT CAUSE:
 * - Will Call services (Subtype__c = 'Will Call'): Client picks up items at warehouse.
 *   No delivery trip is created, so Close Trip flow never runs. These have 
 *   ShoppingAppointmentComplete__c populated instead.
 * 
 * - Some Delivery services: Were marked Completed manually without going through 
 *   the Trip workflow. These usually have LastAppointmentDate__c populated.
 * 
 * SOLUTION:
 * When calculating days outstanding for AR aging, we use this fallback order:
 *   1. ServiceRenderedDate__c (primary - set by Close Trip flow)
 *   2. ShoppingAppointmentComplete__c (for Will Call services)
 *   3. LastAppointmentDate__c (for Delivery services without a trip)
 *   4. CreatedDate (last resort)
 * 
 * This ensures all completed unpaid services are properly aged and actionable.
 * =====================================================================================
 */
public with sharing class AR_OverdueServicesController {
    
    /**
     * Get all services with a balance due that are more than 30 days old, 
     * sorted by days outstanding (oldest first).
     * 
     * Uses fallback date logic for services missing ServiceRenderedDate__c.
     * See class-level comments for full explanation.
     */
    @AuraEnabled(cacheable=true)
    public static List<ServiceWrapper> getOverdueServices() {
        List<ServiceWrapper> results = new List<ServiceWrapper>();
        
        for (Service__c svc : [
            SELECT Id, Name, Agency__c, Agency__r.Name, Contact__c, Contact__r.Name,
                   BalanceDue__c, DaysOutstanding__c, ARAgingBucket__c,
                   ServiceRenderedDate__c, Status__c, Caseworker__c, Caseworker__r.Name, Caseworker__r.Email,
                   Agency__r.Id, Subtype__c, ShoppingAppointmentComplete__c, 
                   LastAppointmentDate__c, CreatedDate, Invoice_Number__c,
                   Agency__r.Primary_Contact__r.Name, Agency__r.Primary_Contact__r.Email
            FROM Service__c
            WHERE BalanceDue__c > 0
              AND (DaysOutstanding__c > 30 OR DaysOutstanding__c = null)
              AND RecordType.DeveloperName = 'ClientRequest'
              AND Agency__r.RecordType.DeveloperName = 'Agency'
              AND Status__c = 'Completed'
              AND CreatedDate >= 2024-02-24T00:00:00Z
            ORDER BY DaysOutstanding__c DESC NULLS LAST
            LIMIT 500
        ]) {
            results.add(new ServiceWrapper(svc));
        }
        
        return results;
    }
    
    /**
     * Get AP Contacts for caseworkers associated with an agency's overdue services
     * Used by the LWC to display AP Contact recipients in the Agency Summary modal
     */
    @AuraEnabled
    public static List<ContactWrapper> getAgencyAPContacts(Id agencyId) {
        // Get caseworker IDs from overdue services for this agency
        Set<Id> caseworkerIds = new Set<Id>();
        for (Service__c svc : [
            SELECT Caseworker__c
            FROM Service__c
            WHERE Agency__c = :agencyId
              AND BalanceDue__c > 0
              AND (DaysOutstanding__c > 30 OR DaysOutstanding__c = null)
              AND RecordType.DeveloperName = 'ClientRequest'
              AND Status__c = 'Completed'
              AND CreatedDate >= 2024-02-24T00:00:00Z
              AND Caseworker__c != null
        ]) {
            caseworkerIds.add(svc.Caseworker__c);
        }
        
        if (caseworkerIds.isEmpty()) {
            return new List<ContactWrapper>();
        }
        
        // Get AP Contacts linked to these caseworkers
        List<ContactWrapper> results = new List<ContactWrapper>();
        for (Contact apContact : [
            SELECT Id, Name, Email
            FROM Contact
            WHERE Id IN (SELECT APContact__c FROM AP_Contact__c WHERE Case_Worker__c IN :caseworkerIds)
            AND Email != null
        ]) {
            results.add(new ContactWrapper(apContact.Id, apContact.Name, apContact.Email));
        }
        
        return results;
    }
    
    /**
     * Simple wrapper for contact info
     */
    public class ContactWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String email;
        
        public ContactWrapper(Id contactId, String contactName, String contactEmail) {
            this.id = contactId;
            this.name = contactName;
            this.email = contactEmail;
        }
    }
    
    /**
     * Log a collection call activity on a service record
     */
    @AuraEnabled
    public static void logCollectionCall(Id serviceId, String notes) {
        Task t = new Task(
            WhatId = serviceId,
            Subject = 'AR Collection Call',
            Status = 'Completed',
            Priority = 'Normal',
            Description = notes,
            ActivityDate = Date.today()
        );
        insert t;
        
        // Update collection tracking
        updateCollectionTracking(serviceId);
    }
    
    /**
     * Write off a service balance
     */
    @AuraEnabled
    public static void writeOffBalance(Id serviceId, String reason, Decimal amount) {
        Service__c svc = [SELECT Id, BalanceDue__c, TotalPaid__c FROM Service__c WHERE Id = :serviceId LIMIT 1];
        
        // If no amount specified, write off full balance
        Decimal writeOffAmount = (amount != null && amount > 0) ? amount : svc.BalanceDue__c;
        
        // Update the service - add to TotalPaid to zero out balance
        svc.TotalPaid__c = (svc.TotalPaid__c != null ? svc.TotalPaid__c : 0) + writeOffAmount;
        svc.WriteOffDate__c = Date.today();
        svc.WriteOffReason__c = reason;
        svc.WriteOffAmount__c = writeOffAmount;
        svc.CollectionsStatus__c = 'Written Off';
        update svc;
        
        // Log activity
        Task t = new Task(
            WhatId = serviceId,
            Subject = 'AR Balance Written Off',
            Status = 'Completed',
            Priority = 'Normal',
            Description = 'Amount: $' + writeOffAmount + '\nReason: ' + reason,
            ActivityDate = Date.today()
        );
        insert t;
    }
    
    /**
     * Record a payment against a service
     */
    @AuraEnabled
    public static void recordPayment(Id serviceId, Decimal amount, String paymentMethod, String notes) {
        Service__c svc = [SELECT Id, TotalPaid__c, BalanceDue__c FROM Service__c WHERE Id = :serviceId LIMIT 1];
        
        // Update total paid
        svc.TotalPaid__c = (svc.TotalPaid__c != null ? svc.TotalPaid__c : 0) + amount;
        
        // If fully paid, update status
        if (svc.BalanceDue__c != null && amount >= svc.BalanceDue__c) {
            svc.CollectionsStatus__c = 'Paid';
        }
        update svc;
        
        // Log activity
        Task t = new Task(
            WhatId = serviceId,
            Subject = 'AR Payment Received',
            Status = 'Completed',
            Priority = 'Normal',
            Description = 'Amount: $' + amount + '\nMethod: ' + paymentMethod + '\nNotes: ' + notes,
            ActivityDate = Date.today()
        );
        insert t;
    }
    
    /**
     * Update collections status
     */
    @AuraEnabled
    public static void updateCollectionsStatus(Id serviceId, String status, String notes) {
        Service__c svc = new Service__c(
            Id = serviceId,
            CollectionsStatus__c = status
        );
        update svc;
        
        // Log activity if notes provided
        if (String.isNotBlank(notes)) {
            Task t = new Task(
                WhatId = serviceId,
                Subject = 'AR Status Update: ' + status,
                Status = 'Completed',
                Priority = 'Normal',
                Description = notes,
                ActivityDate = Date.today()
            );
            insert t;
        }
        
        updateCollectionTracking(serviceId);
    }
    
    /**
     * Get available email templates for collections
     */
    @AuraEnabled(cacheable=true)
    public static List<EmailTemplateWrapper> getEmailTemplates() {
        List<EmailTemplateWrapper> templates = new List<EmailTemplateWrapper>();
        
        for (EmailTemplate et : [
            SELECT Id, Name, Subject, Description, DeveloperName
            FROM EmailTemplate
            WHERE IsActive = true
              AND (Name LIKE '%AR%' OR Name LIKE '%Collection%' OR Name LIKE '%Payment%' OR Name LIKE '%Reminder%')
            ORDER BY Name
            LIMIT 20
        ]) {
            templates.add(new EmailTemplateWrapper(et));
        }
        
        return templates;
    }
    
    /**
     * Send collection email
     */
    @AuraEnabled
    public static void sendCollectionEmail(Id serviceId, Id templateId, String recipientType) {
        Service__c svc = [
            SELECT Id, Agency__c, Agency__r.Name, Agency__r.Primary_Contact__c, 
                   Agency__r.Primary_Contact__r.Email,
                   Contact__c, Contact__r.Email,
                   Caseworker__c, Caseworker__r.Email
            FROM Service__c 
            WHERE Id = :serviceId 
            LIMIT 1
        ];
        
        String toEmail;
        Id targetObjectId;
        
        // For agency, use the Primary Contact's email
        if (recipientType == 'agency' && svc.Agency__r.Primary_Contact__c != null) {
            toEmail = svc.Agency__r.Primary_Contact__r.Email;
            targetObjectId = svc.Agency__r.Primary_Contact__c;
        } else if (recipientType == 'caseworker' && svc.Caseworker__c != null) {
            toEmail = svc.Caseworker__r.Email;
            targetObjectId = svc.Caseworker__c;
        } else if (recipientType == 'client' && svc.Contact__c != null) {
            toEmail = svc.Contact__r.Email;
            targetObjectId = svc.Contact__c;
        }
        
        if (String.isBlank(toEmail)) {
            throw new AuraHandledException('No email address found for ' + recipientType);
        }
        
        // Send email using template
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(templateId);
        mail.setTargetObjectId(targetObjectId);
        mail.setWhatId(serviceId);
        mail.setToAddresses(new List<String>{toEmail});
        mail.setSaveAsActivity(true);
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
        
        // Update collection tracking
        updateCollectionTracking(serviceId);
        
        // Update status to Contacted if not already further along
        Service__c updateSvc = [SELECT Id, CollectionsStatus__c FROM Service__c WHERE Id = :serviceId];
        if (updateSvc.CollectionsStatus__c == null || updateSvc.CollectionsStatus__c == 'Not Started') {
            updateSvc.CollectionsStatus__c = 'Contacted';
            update updateSvc;
        }
    }
    
    /**
     * Helper to update collection tracking fields
     */
    private static void updateCollectionTracking(Id serviceId) {
        Service__c svc = [SELECT Id, CollectionContactCount__c FROM Service__c WHERE Id = :serviceId];
        svc.LastCollectionContactDate__c = Date.today();
        svc.CollectionContactCount__c = (svc.CollectionContactCount__c != null ? svc.CollectionContactCount__c : 0) + 1;
        update svc;
    }
    
    /**
     * Wrapper for email templates
     */
    public class EmailTemplateWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String subject;
        @AuraEnabled public String description;
        
        public EmailTemplateWrapper(EmailTemplate et) {
            this.id = et.Id;
            this.name = et.Name;
            this.subject = et.Subject;
            this.description = et.Description;
        }
    }
    
    /**
     * Wrapper class to provide computed fields and URL.
     * 
     * IMPORTANT: This wrapper calculates "effective" service date and aging using
     * fallback logic when ServiceRenderedDate__c is missing. See class-level comments.
     */
    public class ServiceWrapper {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public String agencyName;
        @AuraEnabled public Id agencyId;
        @AuraEnabled public String agencyUrl;
        @AuraEnabled public String contactName;
        @AuraEnabled public Decimal balanceDue;
        @AuraEnabled public Decimal daysOutstanding;
        @AuraEnabled public String agingBucket;
        @AuraEnabled public String agingClass;
        @AuraEnabled public String agingIcon;
        @AuraEnabled public Date serviceRenderedDate;
        @AuraEnabled public String status;
        @AuraEnabled public String caseworkerEmail;
        @AuraEnabled public String dateSource; // Indicates which date field was used for aging
        @AuraEnabled public String invoiceNumber;
        @AuraEnabled public String agencyPrimaryContactName;
        @AuraEnabled public String agencyPrimaryContactEmail;
        @AuraEnabled public String caseworkerName;
        @AuraEnabled public Id caseworkerId;
        
        public ServiceWrapper(Service__c svc) {
            this.id = svc.Id;
            this.name = svc.Name;
            this.recordUrl = '/lightning/r/Service__c/' + svc.Id + '/view';
            this.agencyName = svc.Agency__r?.Name;
            this.agencyId = svc.Agency__c;
            this.agencyUrl = svc.Agency__c != null ? '/lightning/r/Account/' + svc.Agency__c + '/view' : null;
            this.contactName = svc.Contact__r?.Name;
            this.balanceDue = svc.BalanceDue__c;
            this.status = svc.Status__c;
            this.caseworkerEmail = svc.Caseworker__r?.Email;
            this.invoiceNumber = svc.Invoice_Number__c;
            this.agencyPrimaryContactName = svc.Agency__r?.Primary_Contact__r?.Name;
            this.agencyPrimaryContactEmail = svc.Agency__r?.Primary_Contact__r?.Email;
            this.caseworkerName = svc.Caseworker__r?.Name;
            this.caseworkerId = svc.Caseworker__c;
            this.caseworkerEmail = svc.Caseworker__r?.Email;
            
            // =========================================================================
            // EFFECTIVE DATE FALLBACK LOGIC
            // =========================================================================
            // Determines the "effective" service date for aging calculation.
            // Priority order:
            //   1. ServiceRenderedDate__c (set by Close Trip flow)
            //   2. ShoppingAppointmentComplete__c (for Will Call services)
            //   3. LastAppointmentDate__c (for Delivery services without a trip)
            //   4. CreatedDate (last resort)
            // =========================================================================
            
            DateTime effectiveDateTime;
            
            if (svc.ServiceRenderedDate__c != null) {
                // Primary: Use ServiceRenderedDate if available (set by Close Trip flow)
                effectiveDateTime = svc.ServiceRenderedDate__c;
                this.dateSource = 'Service Rendered';
            } else if (svc.Subtype__c == 'Will Call' && svc.ShoppingAppointmentComplete__c != null) {
                // Will Call fallback: Use Shopping Appointment Complete date
                // (Will Call services don't go through Trip workflow)
                effectiveDateTime = svc.ShoppingAppointmentComplete__c;
                this.dateSource = 'Shopping Complete';
            } else if (svc.LastAppointmentDate__c != null) {
                // Delivery fallback: Use Last Appointment Date
                // (For Delivery services that were completed outside Trip workflow)
                effectiveDateTime = DateTime.newInstance(svc.LastAppointmentDate__c, Time.newInstance(0,0,0,0));
                this.dateSource = 'Last Appointment';
            } else {
                // Last resort: Use Created Date
                effectiveDateTime = svc.CreatedDate;
                this.dateSource = 'Created Date';
            }
            
            // Set the displayed service date
            this.serviceRenderedDate = effectiveDateTime.date();
            
            // Calculate days outstanding from effective date
            this.daysOutstanding = Date.today().daysBetween(effectiveDateTime.date()) * -1;
            
            // Calculate aging bucket from effective days outstanding
            if (this.daysOutstanding <= 30) {
                this.agingBucket = 'Current (0-30 Days)';
                this.agingClass = 'aging-current';
                this.agingIcon = '🟢';
            } else if (this.daysOutstanding <= 60) {
                this.agingBucket = '31-60 Days';
                this.agingClass = 'aging-caution';
                this.agingIcon = '🟡';
            } else if (this.daysOutstanding <= 90) {
                this.agingBucket = '61-90 Days';
                this.agingClass = 'aging-warning';
                this.agingIcon = '🟠';
            } else {
                this.agingBucket = '90+ Days';
                this.agingClass = 'slds-text-color_error aging-critical';
                this.agingIcon = '🔴';
            }
        }
    }
    
    // =========================================================================
    // AGENCY SUMMARY EMAIL (Added Jan 2026)
    // =========================================================================
    // Sends a consolidated email to an agency listing all their outstanding 
    // services with a total balance. This allows collections staff to send
    // one email covering multiple services instead of individual emails.
    // =========================================================================
    
    /**
     * Send a summary email to an agency with all their outstanding services
     * Sends to: Primary Contact (if available) + all Caseworkers with overdue services
     * @param agencyId The Account ID of the agency
     */
    @AuraEnabled
    public static void sendAgencySummaryEmail(Id agencyId) {
        // Get agency info and primary contact
        Account agency = [
            SELECT Id, Name, Primary_Contact__c, Primary_Contact__r.Email, 
                   Primary_Contact__r.FirstName, Primary_Contact__r.LastName
            FROM Account 
            WHERE Id = :agencyId 
            LIMIT 1
        ];
        
        // Get all overdue services for this agency (including caseworker info)
        List<Service__c> services = [
            SELECT Id, Name, Contact__r.Name, BalanceDue__c, DaysOutstanding__c,
                   ServiceRenderedDate__c, Subtype__c, ShoppingAppointmentComplete__c,
                   LastAppointmentDate__c, CreatedDate, CollectionContactCount__c,
                   CollectionsStatus__c, Caseworker__c, Caseworker__r.Name, Caseworker__r.Email
            FROM Service__c
            WHERE Agency__c = :agencyId
              AND BalanceDue__c > 0
              AND (DaysOutstanding__c > 30 OR DaysOutstanding__c = null)
              AND RecordType.DeveloperName = 'ClientRequest'
              AND Status__c = 'Completed'
              AND CreatedDate >= 2024-02-24T00:00:00Z
            ORDER BY DaysOutstanding__c DESC NULLS LAST
        ];
        
        if (services.isEmpty()) {
            throw new AuraHandledException('No overdue services found for ' + agency.Name);
        }
        
        // Build recipient list: Primary Contact + unique Caseworkers + AP Contacts
        List<String> toAddresses = new List<String>();
        Set<String> addedEmails = new Set<String>(); // Prevent duplicates
        List<String> recipientNames = new List<String>();
        Id targetContactId = null;
        Set<Id> caseworkerIds = new Set<Id>();
        
        // Add Primary Contact if available
        if (agency.Primary_Contact__c != null && String.isNotBlank(agency.Primary_Contact__r.Email)) {
            toAddresses.add(agency.Primary_Contact__r.Email);
            addedEmails.add(agency.Primary_Contact__r.Email.toLowerCase());
            recipientNames.add(agency.Primary_Contact__r.FirstName + ' ' + agency.Primary_Contact__r.LastName + ' (Primary Contact)');
            targetContactId = agency.Primary_Contact__c;
        }
        
        // Add Caseworkers with valid emails (avoid duplicates) and collect caseworker IDs
        for (Service__c svc : services) {
            if (svc.Caseworker__c != null) {
                caseworkerIds.add(svc.Caseworker__c);
                if (String.isNotBlank(svc.Caseworker__r.Email)) {
                    String email = svc.Caseworker__r.Email.toLowerCase();
                    if (!addedEmails.contains(email)) {
                        toAddresses.add(svc.Caseworker__r.Email);
                        addedEmails.add(email);
                        recipientNames.add(svc.Caseworker__r.Name + ' (Caseworker)');
                        // Use first caseworker as target if no primary contact
                        if (targetContactId == null) {
                            targetContactId = svc.Caseworker__c;
                        }
                    }
                }
            }
        }
        
        // Add AP Contacts linked to the caseworkers
        if (!caseworkerIds.isEmpty()) {
            List<Contact> apContacts = [
                SELECT Id, Name, Email
                FROM Contact
                WHERE Id IN (SELECT APContact__c FROM AP_Contact__c WHERE Case_Worker__c IN :caseworkerIds)
                AND Email != null
            ];
            for (Contact apContact : apContacts) {
                String email = apContact.Email.toLowerCase();
                if (!addedEmails.contains(email)) {
                    toAddresses.add(apContact.Email);
                    addedEmails.add(email);
                    recipientNames.add(apContact.Name + ' (AP Contact)');
                    if (targetContactId == null) {
                        targetContactId = apContact.Id;
                    }
                }
            }
        }
        
        // Must have at least one recipient
        if (toAddresses.isEmpty()) {
            throw new AuraHandledException('No email recipients found. Please ensure the agency has a Primary Contact, caseworkers, or AP contacts with email addresses.');
        }
        
        // Calculate total
        Decimal totalBalance = 0;
        for (Service__c svc : services) {
            totalBalance += svc.BalanceDue__c;
        }
        
        // Build email body
        String emailBody = buildAgencySummaryEmailBody(agency, services, totalBalance);
        
        // Send email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAddresses);
        mail.setSubject('Outstanding Balance Summary - $' + totalBalance.setScale(2) + ' - Northwest Furniture Bank');
        mail.setHtmlBody(emailBody);
        mail.setSaveAsActivity(true);
        mail.setWhatId(agencyId); // Link to the Agency account
        mail.setTargetObjectId(targetContactId); // Link to a contact for activity tracking
        mail.setTreatTargetObjectAsRecipient(false);
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        
        // Update collection tracking on all services
        List<Service__c> servicesToUpdate = new List<Service__c>();
        for (Service__c svc : services) {
            Service__c updateSvc = new Service__c(Id = svc.Id);
            updateSvc.LastCollectionContactDate__c = Date.today();
            updateSvc.CollectionContactCount__c = (svc.CollectionContactCount__c != null ? svc.CollectionContactCount__c : 0) + 1;
            if (svc.CollectionsStatus__c == null || svc.CollectionsStatus__c == 'Not Started') {
                updateSvc.CollectionsStatus__c = 'Contacted';
            }
            servicesToUpdate.add(updateSvc);
        }
        update servicesToUpdate;
        
        // Log activity on the Agency account
        Task t = new Task(
            WhatId = agencyId,
            Subject = 'AR Summary Email Sent',
            Status = 'Completed',
            Priority = 'Normal',
            Description = 'Sent AR summary email to ' + String.join(recipientNames, ', ') + ' for ' + services.size() + ' services totaling $' + totalBalance.setScale(2),
            ActivityDate = Date.today()
        );
        insert t;
    }
    
    /**
     * Build the HTML email body for the agency summary
     */
    private static String buildAgencySummaryEmailBody(Account agency, List<Service__c> services, Decimal totalBalance) {
        String body = '<html><body style="font-family: Arial, sans-serif; color: #333;">';
        
        // Header
        body += '<div style="background-color: #0070d2; color: white; padding: 20px; text-align: center;">';
        body += '<h1 style="margin: 0;">Outstanding Balance Summary</h1>';
        body += '<p style="margin: 5px 0 0 0; font-size: 14px;">Northwest Furniture Bank</p>';
        body += '</div>';
        
        // Greeting
        body += '<div style="padding: 20px;">';
        body += '<p>Dear ' + agency.Name + ',</p>';
        body += '<p>Our records indicate your agency has <strong>' + services.size() + ' service(s)</strong> ';
        body += 'with a combined outstanding balance of <strong style="color: #c23934;">$' + totalBalance.setScale(2) + '</strong>.</p>';
        
        // Services table
        body += '<table style="width: 100%; border-collapse: collapse; margin: 20px 0;">';
        body += '<thead><tr style="background-color: #f4f6f9;">';
        body += '<th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Service</th>';
        body += '<th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Client</th>';
        body += '<th style="padding: 10px; border: 1px solid #ddd; text-align: left;">Service Date</th>';
        body += '<th style="padding: 10px; border: 1px solid #ddd; text-align: right;">Balance</th>';
        body += '</tr></thead><tbody>';
        
        for (Service__c svc : services) {
            // Calculate effective date using same fallback logic
            Date effectiveDate;
            if (svc.ServiceRenderedDate__c != null) {
                effectiveDate = svc.ServiceRenderedDate__c.date();
            } else if (svc.Subtype__c == 'Will Call' && svc.ShoppingAppointmentComplete__c != null) {
                effectiveDate = svc.ShoppingAppointmentComplete__c.date();
            } else if (svc.LastAppointmentDate__c != null) {
                effectiveDate = svc.LastAppointmentDate__c;
            } else {
                effectiveDate = svc.CreatedDate.date();
            }
            
            String dateStr = effectiveDate != null ? effectiveDate.format() : 'N/A';
            String clientName = svc.Contact__r?.Name != null ? svc.Contact__r.Name : 'N/A';
            
            body += '<tr>';
            body += '<td style="padding: 10px; border: 1px solid #ddd;">' + svc.Name + '</td>';
            body += '<td style="padding: 10px; border: 1px solid #ddd;">' + clientName + '</td>';
            body += '<td style="padding: 10px; border: 1px solid #ddd;">' + dateStr + '</td>';
            body += '<td style="padding: 10px; border: 1px solid #ddd; text-align: right;">$' + svc.BalanceDue__c.setScale(2) + '</td>';
            body += '</tr>';
        }
        
        // Total row
        body += '<tr style="background-color: #f4f6f9; font-weight: bold;">';
        body += '<td colspan="3" style="padding: 10px; border: 1px solid #ddd; text-align: right;">TOTAL DUE:</td>';
        body += '<td style="padding: 10px; border: 1px solid #ddd; text-align: right; color: #c23934;">$' + totalBalance.setScale(2) + '</td>';
        body += '</tr>';
        
        body += '</tbody></table>';
        
        // Footer
        body += '<p>Please remit payment at your earliest convenience. If you have questions about any of these services, please contact us.</p>';
        body += '<p>Thank you,<br/><strong>Northwest Furniture Bank</strong><br/>Accounts Receivable</p>';
        body += '</div>';
        
        body += '</body></html>';
        
        return body;
    }
}