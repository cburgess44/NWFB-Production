@IsTest
public with sharing class CampaignDaoTest {

    @isTest
    public static void testCreateCampaign(){
        Campaign campaign = new Campaign(Name ='test', MaximumMembersAllowed__c = 10, IsActive = true);
        insert campaign;
        update campaign;

        CampaignDao campaigndaoClass = CampaignDao.getInstance();

    }
}