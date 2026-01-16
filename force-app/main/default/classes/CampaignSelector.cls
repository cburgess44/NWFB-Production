public with sharing class CampaignSelector {
    private static CampaignSelector instance = null;

    public static CampaignSelector getInstance() {
        if (instance == null) {
            instance = new CampaignSelector();
        }
        return instance;
    }

    public Map<Id, Campaign> getActiveCampaignsByIds(Set<Id> campaignIdSet) {
        return new Map<Id, Campaign>([
                SELECT Id, MaximumMembersAllowed__c, IsActive, (SELECT Id FROM CampaignMembers)
                FROM Campaign 
                WHERE Id IN : campaignIdSet AND IsActive = TRUE
        ]);
    }
}