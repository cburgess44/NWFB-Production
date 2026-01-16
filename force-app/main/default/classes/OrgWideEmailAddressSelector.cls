public with sharing class OrgWideEmailAddressSelector { 
    private static OrgWideEmailAddressSelector instance = null;

    public static OrgWideEmailAddressSelector getInstance() {
        if (instance == null) {
            instance = new OrgWideEmailAddressSelector();
        }
        return instance;
    }

    public Map<String, OrgWideEmailAddress> getOrgWideEmailAddressByEmailAddress(String emailAddress){
        Map<String, OrgWideEmailAddress> addressToOrgWideEmail = new Map<String, OrgWideEmailAddress>();

        List<OrgWideEmailAddress> orgWideEmailList = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address =: emailAddress];

        for(OrgWideEmailAddress orgWideEmail : orgWideEmailList){
            addressToOrgWideEmail.put(orgWideEmail.Address, orgWideEmail);
        }
        
        return addressToOrgWideEmail;
    }

    public OrgWideEmailAddress getOrgWideEmailAddress(String emailAddress){
        return [
                SELECT
                        Id,
                        Address
                FROM OrgWideEmailAddress
                WHERE Address =: emailAddress
                LIMIT 1
        ];
    }
}