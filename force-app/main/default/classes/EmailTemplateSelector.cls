public with sharing class EmailTemplateSelector { 

    private static EmailTemplateSelector instance = null;

    public static EmailTemplateSelector getInstance() {
        if (instance == null) {
        instance = new EmailTemplateSelector();
        }
        return instance;
    }

    public EmailTemplate getEmailTemplateByName(String name){
        List<EmailTemplate> et = [SELECT 
                Id,Name
                FROM EmailTemplate 
                WHERE Name = :name LIMIT 1];
        return et.size() > 0 ? et[0] : new EmailTemplate();
    }

    public EmailTemplate getEmailTemplateByDeveloperName(String developerName) {
        return [
            SELECT
                Id
            FROM EmailTemplate
            WHERE DeveloperName = :developerName
            LIMIT 1
        ][0];
    }

    public Map<String, EmailTemplate> getEmailTemplatesByNames(List<String> nameList){
        Map<String, EmailTemplate> emailTemplatesByNameMap = new Map<String, EmailTemplate>();

        List<EmailTemplate> emailsTemplates = [SELECT 
                Id, Name
                FROM EmailTemplate 
                WHERE Name IN : nameList ];

        for(EmailTemplate emailTemplate : emailsTemplates){
            emailTemplatesByNameMap.put(emailTemplate.Name, emailTemplate);
        }
        
        return emailTemplatesByNameMap;
    }

    public Map<String, EmailTemplate> getEmailTemplatesByDeveloperNames(List<String> nameList){
        Map<String, EmailTemplate> emailTemplatesByNameMap = new Map<String, EmailTemplate>();

        List<EmailTemplate> emailsTemplates = [SELECT
                Id, DeveloperName
        FROM EmailTemplate
        WHERE DeveloperName IN : nameList ];

        for(EmailTemplate emailTemplate : emailsTemplates){
            emailTemplatesByNameMap.put(emailTemplate.DeveloperName, emailTemplate);
        }

        return emailTemplatesByNameMap;
    }
}