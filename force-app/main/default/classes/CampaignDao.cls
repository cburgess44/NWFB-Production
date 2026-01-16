public with sharing class CampaignDao extends GenericDao {
    @TestVisible
    private static CampaignDao mock;
    public CampaignDao() {

    }
    private CampaignDao(List<SObject> Campaign, Map<Id, SObject> oldCampaignById) {
        super(Campaign, oldCampaignById);
    }
    private CampaignDao(List<SObject> Campaign) {
        super(Campaign);
    }

    public static CampaignDao getInstance() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return new CampaignDao(new List<Campaign>());
        }
    }

    public class Factory implements TriggerHandlerFactory {
        public TriggerHandler create(List<SObject> objects, Map<Id, SObject> oldObjectsById) {
            return new CampaignDao(objects, oldObjectsById);
        }
    }

    public override void beforeInsert() {
        
    }

    public override void beforeUpdate() {
        setInactiveByMembersAmount();
    }

    private void setInactiveByMembersAmount(){
        Map<String, Schema.RecordTypeInfo> recordTypeInfos = Campaign.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();   
        Id orientationRecordType = recordTypeInfos?.get('Orientation')?.getRecordTypeId();

        Map<Id, Campaign> newRecordsMap = new Map<Id, Campaign>((List<Campaign>) this.records);
        Map<Id, Campaign> oldRecordsMap = this.oldRecordsById == null ? new Map<Id, Campaign>() : (Map<Id, Campaign>) this.oldRecordsById;

        Map<Id, Campaign> campaignDataMap = CampaignSelector.getInstance().getActiveCampaignsByIds(newRecordsMap.keySet());

        for (Campaign campaign : campaignDataMap.values()) {
            Campaign oldCampaign = oldRecordsMap.get(campaign.Id);
 //           Boolean shouldBeSkiped = (campaign?.CampaignMembers?.isEmpty() || campaign.RecordType != orientationRecordType);
			Boolean shouldBeSkiped = false;
            if (shouldBeSkiped) continue;

            Boolean shouldChangeToIncative = (campaign.MaximumMembersAllowed__c == campaign?.CampaignMembers?.size()
                                                && oldCampaign?.CampaignMembers?.size() != campaign?.CampaignMembers?.size());    

            Boolean shouldShowError = (oldCampaign != null 
                                        && oldCampaign?.CampaignMembers?.size() != campaign?.CampaignMembers?.size() 
                                        && campaign?.CampaignMembers?.size() > campaign.MaximumMembersAllowed__c);

            if (shouldChangeToIncative) {
                campaign.IsActive = false;

            } else if (shouldShowError) {
                campaign.addError('The Maximum members of ' + campaign.MaximumMembersAllowed__c  + ' has been reached for this campaign! Please, contact your administrator for further information.');
                
            }
        }
    }
}