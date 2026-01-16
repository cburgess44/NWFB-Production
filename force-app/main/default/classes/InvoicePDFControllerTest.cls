/**
 * Created by Gustavo on 10/01/24.
 */

@IsTest
private class InvoicePDFControllerTest {
    @IsTest
    static void setItemsForPDF() {
        Service__c service = new Service__c(
                Name = 'Test',
                Processing_Fee__c = 1,
                Delivery_Fee__c = 1,
                SubTotal__c = 10,
                TotalTaxableAmount__c = 10,
                TotalPaid__c = 20
        );
        insert service;

        PageReference pageRef = Page.InvoicePDF;
        pageRef.getParameters().put('id', service.Id);
        Test.setCurrentPage(pageRef);

        new InvoicePDFController().setItemsForPDF();
    }
}