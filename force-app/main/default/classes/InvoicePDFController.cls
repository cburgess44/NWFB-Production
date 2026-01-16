public without sharing class InvoicePDFController {

    public List<ServiceItem__c> items { get; set; }
    public List<ServiceFee> feeItems { get; set; }
    public List<Payment__c> payments { get; set; }
    public Date today {get; set;}
    public Service__c service { get; set; }
    public Decimal serviceBalanceDue { get; set; }
    //public Map<String, Decimal> totals { get; set; }

    public class ServiceFee {
        public String name { get; set; }
        public Integer quantity { get; set; }
        public Decimal totalItemPrice { get; set; }
        public Decimal totalFee { get; set; }
    }

    public InvoicePDFController() {
        setItemsForPDF();
    }

    public void setItemsForPDF() {
        String serviceId = ApexPages.currentPage().getParameters().get('id');
        today = Date.today();

        // get service details and format
        service = [
                SELECT
                        Id,
                        Name,
                        CreatedDate,
                        InvoiceDue__c,
                        Invoice_Number__c,
                        Processing_Fee__c,
                        Delivery_Fee__c,
                        SubTotal__c,
                        TotalTaxableAmount__c,
                        TotalPaid__c,
                        BalanceDue__c,
                        TotalAmount__c,
                        Contact__r.Name,
                        Contact__r.MobilePhone,
                        CaseworkerName__c,
                        LastAppointmentDate__c,
                        Caseworker__r.Email,
                        InvoiceVersion__c,
                        InvoiceNumberVersion__c,
                        Agency__r.Name,
                        Agency__r.BillingStreet,
                        Agency__r.BillingCity, Agency__r.BillingState,
                        Agency__r.BillingPostalCode,
                        ProcessingFeeBalanceDue__c,
                        Due_Date_Invoice_1__c
                FROM Service__c
                WHERE Id = :serviceId
        ];

        if (service.TotalTaxableAmount__c == null) service.TotalTaxableAmount__c = 0;
        if (service.TotalPaid__c == null) service.TotalPaid__c = 0;

        // set fees
        feeItems = new List<ServiceFee>();
        if (service.Delivery_Fee__c > 0 && service.InvoiceVersion__c != 1) {
            ServiceFee si = new ServiceFee();
            si.name = 'Delivery Fee';
            si.quantity = 1; 
            si.totalItemPrice = service.Delivery_Fee__c;
            si.totalFee = service.Delivery_Fee__c;
            feeItems.add(si);
        }

        if (service.Processing_Fee__c > 0) {
            ServiceFee si = new ServiceFee();
            si.name = 'Processing Fee';
            si.quantity = 1;
            si.totalItemPrice = service.Processing_Fee__c;
            si.totalFee = service.Processing_Fee__c;
            feeItems.add(si);
            serviceBalanceDue = service.Processing_Fee__c - service.TotalPaid__c;
        }

        // get items and format
        List<ServiceItem__c> serviceItems = new ServiceItemSelector().getServiceItemsByServiceId(serviceId);
        items = new List<ServiceItem__c>();
        if (service.InvoiceVersion__c != 1) {
            for (ServiceItem__c item : serviceItems) {
                if (item.Quantity__c > 0 && item.TotalItemPrice__c != null && item.TotalItemPrice__c > 0){
                    items.add(item);
                }
            }
        }


        // get payments
        payments = new List<Payment__c>();
        payments = [
                SELECT
                        Id,
                        Name,
                        PaymentMethod__c,
                        PaymentAmount__c,
                        Payee_Type__c,
                        CardLast4Digits__c,
                        CreatedDate
                FROM Payment__c
                WHERE Service__c = :serviceId
        ];

    }
}