public class SendSMSQueueable implements Queueable, Database.AllowsCallouts  {
    public String phNumber;
    public String body;
    public String locationName;

    public SendSMSQueueable(String locationName, String phNumber, String body) {
        this.locationName = locationName;
        this.phNumber = phNumber;
        this.body = body;
    }

    public void execute(QueueableContext context) {
        NWFBSettings__c settings = NWFBSettings__c.getOrgDefaults();
        if (!settings.DisableSMS__c) {
            TwillioIntegrationApi tw = new TwillioIntegrationApi(this.locationName, this.phNumber, this.body);
            tw.sendSMS();
        }
    }
}