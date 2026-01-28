import {api, LightningElement, track, wire} from 'lwc';
import listSObjects from '@salesforce/apex/SObjectCRUDController.listSObjects';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {CurrentPageReference, NavigationMixin} from 'lightning/navigation';
import NoInvoiceLabel from '@salesforce/label/c.NoInvoiceLabel';

const COLS = [
    {label: 'Description', fieldName: 'Name'},
    {label: 'Due Date', fieldName: 'DueDate__c', type: 'date'},
    {label: 'Original Amount', fieldName: 'TotalCost__c', type: 'currency'},
    {label: 'Open balance', fieldName: 'BalanceDue__c', type: 'currency'},
    {label: 'Payment Amount', fieldName: 'TotalPaidb__c', type: 'currency', editable: false}
];

const SERVICECOLS = [
    {label: 'Invoice #', fieldName: 'Invoice_Number__c', type: 'text'},
    {label: 'Description', fieldName: 'Name'},
    {label: 'Original Amount', fieldName: 'TotalAmount__c', type: 'currency'},
    {label: 'Balance Due', fieldName: 'BalanceDue__c', type: 'currency'},
    {label: 'Payment Amount', fieldName: 'PaymentAmount', type: 'currency', editable: true}
];


export default class InvoicePayments extends NavigationMixin(LightningElement) {
    label = {
        NoInvoiceLabel
    };

    @api
    recordId;

    @api
    paymentId;

    @api
    invoiceId;

    @track
    invoices = [];

    @track
    selectedRows = [];

    @track
    parentPayment;

    @track
    showNoInvoiceMessage = true;

    payments = [];
    data = SERVICECOLS;
    selectedInvoices = [];
    currentAccount;
    newInvoicePayment = [];
    value = 'Check';
    userFields;
    loading = false;
    draftValues = [];

    constructor() {
        super();
        this.parentPayment = {
            sobjectType: 'Payment__c',
            PaymentMethod__c: 'Check',
            PaymentDate__c: new Date().toISOString(),
            PaymentAmount__c: 0.00
        };
        this.userFields = {};
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
    }

    async connectedCallback() {
        this.initParameters();
        await this.getAccount();
        await this.getServices();
    }

    initParameters() {
        if (this.recordId) return;
        const {c__accountId, c__invoiceId} = this.currentPageReference.state;
        this.recordId = c__accountId;
        this.invoiceId = c__invoiceId;
    }

    handleInputChange(event) {
        this.parentPayment[event.target.name] = event.target.value;
    }

    get showData() {
        return this.invoices.length > 0;
    }

    get showCardForm() {
        return (this.parentPayment.PaymentMethod__c === 'CreditCard');
    }

    get disableCheckForm() {
        return (this.parentPayment.PaymentMethod__c !== 'Check' || this.selectedInvoices.length === 0);
    }

    get methodOptions() {
        return [
            {label: 'Check', value: 'Check'},
            {label: 'Credit Card', value: 'CreditCard'},
        ];
    }

    get cardTitle() {
        return this.currentAccount.Name;
    }

    async getAccount() {
        try {
            this.loading = true;

            const filterAccount = (
                `AND Id = '${this.recordId}' `
            );

            const result = await listSObjects({
                objectName: 'Account',
                fields: [
                    'Id',
                    'Name'
                ],
                filters: filterAccount
            });

            if (result === null) {
                this.loading = false;
                return;
            }

            this.currentAccount = result[0];
            this.loading = false;
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    async getInvoices() {
        try {
            this.loading = true;

            const filter = (
                `AND Agency__c = '${this.recordId}' `
            );

            const result = await listSObjects({
                objectName: 'Invoice__c',
                fields: [
                    'Id',
                    'Name',
                    'Agency__c',
                    'Agency__r.Name',
                    'Service__c',
                    'DueDate__c',
                    'TotalCost__c',
                    'TotalPaid__c',
                    'TotalPaidb__c',
                    'BalanceDue__c',
                ],
                filters: filter
            });

            if (result === null) {
                this.loading = false;
                return;
            }

            this.invoices = result.map((row) => {
                return this.mapInvoices(row);
            });

            if (this.invoiceId) this.selectedRows = [this.invoiceId];
            this.loading = false;
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }

    }

    async getServices() {
        try {
            this.loading = true;

            const filter = (
                `AND Agency__c = '${this.recordId}' AND BalanceDue__c > 0 `
            );

            const result = await listSObjects({
                objectName: 'Service__c',
                fields: [
                    'Id',
                    'Name',
                    'Agency__c',
                    'Agency__r.Name',
                    'Invoice_Number__c',
                    'TotalAmount__c',
                    'BalanceDue__c',
                ],
                filters: filter
            });

            if (result === null || result.length === 0) {
                this.loading = false;
                return;
            }

            this.invoices = result.map((row) => {
                // Default payment amount to balance due
                row.PaymentAmount = row.BalanceDue__c;
                return row;
            });
            this.loading = false;
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    handlePaymentDataChange(event) {
        this.parentPayment[event.target.name] = event.detail.value;
        this.userFields.parentPayment = this.parentPayment;
        this.validateDate();
    }

    mapInvoices(row) {
        let invoiceName = '';
        if (row.Name) invoiceName = row.Name;

        let dueDate = null;
        if (row.DueDate__c) dueDate = row.DueDate__c;

        let originalAmount = null;
        if (row.TotalCost__c) originalAmount = row.TotalCost__c;

        let openBalance = null;
        if (row.BalanceDue__c) openBalance = row.BalanceDue__c;

        let id = null;
        if (row.Id) id = row.Id;

        let totalToPay = null;
        if(row.TotalPaid__c){
            totalToPay = row.TotalCost__c - row.TotalPaid__c;
        }
        else{
            totalToPay = openBalance;
        }

        return {
            ...row,
            Id: id,
            Name: invoiceName,
            DueDate__c: dueDate,
            TotalCost__c: originalAmount,
            BalanceDue__c: openBalance,
            TotalPaidb__c: totalToPay,
        };

    }

    validateDate(){
        let isValid = true;

        if (!this.parentPayment['PaymentDate__c']) {

            this.showToast(
                'Payment Date missing',
                'You need to fill in the payment date',
                'warning'
            );

            this.selectedRows = [];
            this.selectedInvoices=[];
            this.showNoInvoiceMessage = true;
            isValid = false;
        }

        return isValid;
    }

    handleRowSelection(event){
        if (!this.validateDate()) {
            return;
        }

        this.selectedInvoices = event.detail.selectedRows;
        this.showNoInvoiceMessage = this.selectedInvoices.length <= 0;

        this.recalculatePaymentTotals();
    }

    handleCellChange(event) {
        const draftValues = event.detail.draftValues;
        
        // Update the invoices array with edited payment amounts
        draftValues.forEach(draft => {
            const invoice = this.invoices.find(inv => inv.Id === draft.Id);
            if (invoice && draft.PaymentAmount !== undefined) {
                invoice.PaymentAmount = Number(draft.PaymentAmount);
            }
        });

        // Clear draft values
        this.template.querySelector('lightning-datatable').draftValues = [];

        this.recalculatePaymentTotals();
    }

    recalculatePaymentTotals() {
        const invoicePayments = [];
        this.newInvoicePayment = [];

        let totalToPay = 0;

        for (const selectedInvoice of this.selectedInvoices) {
            // Find the current invoice to get the possibly-edited PaymentAmount
            const currentInvoice = this.invoices.find(inv => inv.Id === selectedInvoice.Id);
            const paymentAmount = currentInvoice ? currentInvoice.PaymentAmount : selectedInvoice.BalanceDue__c;

            totalToPay += paymentAmount;
            invoicePayments.push({
                Amount__c: Number(paymentAmount),
                Service__c: selectedInvoice.Id
            });

            this.newInvoicePayment.push({
                sobjectType: 'ServicePayment__c',
                Amount__c: Number(paymentAmount),
                Payment__c: '',
                Service__c: selectedInvoice.Id
            });
        }

        this.userFields.invoicePayments = invoicePayments;
        this.parentPayment.PaymentAmount__c = totalToPay;

        if (this.showCardForm) {
            this.template.querySelector('c-clover-connect-payment-form').reload(totalToPay);
        }
    }

    async handleSubmitPayment() {
        try {
            this.loading = true;

            let inputs = this.template.querySelectorAll('lightning-input');

            for (let i = 0; i < inputs.length; i++) {
                if (inputs[i].value) continue;
                this.loading = false;
                this.showToast(
                    'Payment Date missing',
                    'You should complete Payment Date and Total Payment Amount before submitting the payment',
                    'error'
                );
            }

            if (this.selectedInvoices.length === 0) {
                this.showToast(
                    'No invoice selected',
                    'You should select at least one Invoice before submitting the payment',
                    'error'
                );
                this.loading = false;
                return;
            }


            this.parentPayment.Status__c = 'Processed';

            this.payments.push(this.parentPayment);
            this.payments = await saveSObjects({sObjects: this.payments});


            if (this.payments.length === 0) {
                this.loading = false;
                return;
            }

            for (const payment of this.newInvoicePayment) {
                payment.Payment__c = this.payments[0].Id;
            }

            this.newInvoicePayment = await saveSObjects({sObjects: this.newInvoicePayment});
            this.showToast(
                'Payment Approved',
                'Your payment has been successfully approved',
                'success'
            );
            window.location = `/lightning/r/ServicePayment__c/${this.newInvoicePayment[0].Id}/view`;
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }

    }

    async handleAfterSubmit(event) {
        if (event.detail.respstat === 'A') {
            this.loading = true;
            this.showToast(
                'Payment Approved',
                'Your payment has been successfully approved',
                'success'
            );
            await this.loadLastServicePayment();
        } else if (event.detail.respstat === 'B') {
            this.showToast(
                'Retry Payment',
                'Please retry your payment',
                'warning'
            );
        } else if (event.detail.respstat === 'C') {
            this.showToast(
                'Payment Denied',
                'Your payment has been denied, please review your data or try with another card',
                'error'
            );
        }
    }

    async loadLastServicePayment() {
        try {
            const servicesPayment = await listSObjects({
                objectName: 'ServicePayment__c',
                fields: ['Id'],
                filters: `ORDER BY CreatedDate DESC`
            });

            window.location = `/lightning/r/ServicePayment__c/${servicesPayment[0].Id}/view`
        } catch (e) {
            console.error('Error ', e);
            this.loading = false;
        }
    }

    //show toast method
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            Title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
        }));
    }

}