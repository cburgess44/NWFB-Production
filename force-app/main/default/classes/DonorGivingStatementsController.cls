/**
 * Created by Gustavo on 10/02/25.
 */

public without sharing class DonorGivingStatementsController {
    public List<Opportunity> opportunities { get; set; }
    public Contact contact { get; set; }
    public Decimal totalAmount { get; set; }
    public Decimal totalDeductibleAmount { get; set; }
    public Opportunity largestOpportunity { get; set; }
    public Opportunity lastOpportunity { get; set; }
    public Opportunity firstOpportunity { get; set; }
    public Date todayDate { get; set; }
    public Date fromDate { get; set; }
    public Date toDate { get; set; }

    public DonorGivingStatementsController() {
        initPDFItems();
    }

    public void initPDFItems() {
        String contactId = ApexPages.currentPage().getParameters().get('id');
        todayDate = Date.today();
        fromDate = Date.valueOf(ApexPages.currentPage().getParameters().get('from'));
        toDate = Date.valueOf(ApexPages.currentPage().getParameters().get('to'));

        contact = [
                SELECT
                Id,
                Name,
                        FirstName,
                        LastName,
                        MobilePhone,
                        HomePhone,
                        Email,
                        LGL_ID__c,
                        Salutation,
                        MailingState,
                        MailingCity,
                        MailingCountry,
                        MailingStreet,
                        MailingPostalCode
                FROM Contact
                WHERE Id = :contactId
        ];


        opportunities = [
                SELECT
                        Id,
                        Name,
                        CloseDate,
                        Amount,
                        Deductible_Amount__c,
                        Appeal__c,
                        Appeal__r.Name,
                        Gift_Type__c,
                        Campaign__r.Name,
                        Payment_Type__c,
                        Gift_Category__c,
                        General_Accounting_Unit__c
                FROM Opportunity
                WHERE ContactId = :contactId
                        AND CloseDate >= :fromDate
                        AND CloseDate <= :toDate
                        AND StageName = 'Closed/Won'
        ];

        Decimal totalOpportunitiesAmount = 0;
        Decimal totalOpportunitiesDeductibleAmount = 0;
        for (Opportunity opp : opportunities) {
            totalOpportunitiesAmount += opp.Amount;
            totalOpportunitiesDeductibleAmount += opp.Deductible_Amount__c != null ? opp.Deductible_Amount__c : 0;

            if (largestOpportunity == null || largestOpportunity.Amount < opp.Amount) {
                largestOpportunity = opp;
            }

            if (lastOpportunity == null || lastOpportunity.CloseDate < opp.CloseDate) {
                lastOpportunity = opp;
            }

            if (firstOpportunity == null || firstOpportunity.CloseDate > opp.CloseDate) {
                firstOpportunity = opp;
            }
        }

        totalAmount = totalOpportunitiesAmount;
        totalDeductibleAmount = totalOpportunitiesDeductibleAmount;

    }
}