/**
 * Created by Gustavo on 22/06/23.
 */

import {api, LightningElement, track, wire} from 'lwc';

import listSObjects from '@salesforce/apex/SObjectCRUDController.listSObjects';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';

import {getSfDate} from "c/utils";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { CurrentPageReference } from 'lightning/navigation';
import { NavigationMixin } from 'lightning/navigation';

export default class ServicePayment extends NavigationMixin(LightningElement) {
    @api
    recordId;

    @track
    payments;

    @track
    paymentType;

    @track
    refundPayment;

    @track
    userFields;

    @track
    enableProfileManager;

    @track
    manualPayment;

    @track
    message;

    payee;
    payeeTypes;
    paymentTypes;
    service;
    tableColumn;
    loading;

    constructor() {
        super();
        this.init();
    }

    // @wire(CurrentPageReference) pageRef;

    async connectedCallback() {
        await this.loadServiceInformation();
        await this.loadPayments();
        this.setupTableColumn();
    }

    init() {
        this.payments = [];
        this.manualPayment = {};
        this.userFields = {};
        this.service = null;
        this.enableProfileManager = false;
        this.loading = false;
        this.paymentType = 'CreditCard';
        this.payee ='Client';
        this.payeeTypes = [
            {label: 'Client', value: 'Client'},
            {label: 'Agency', value: 'Agency'},
            {label: 'Other', value: 'Other'},
        ];
        this.paymentTypes = [
            {label: 'Card', value: 'CreditCard'},
            {label: 'Check', value: 'Check'},
            {label: 'Cash', value: 'Cash'},
        ];
        this.message = `If no saved cards available, you can enter a new card to the list on "Manage Payment Methods" 
        button.`;
    }

    async loadServiceInformation() {
        try {
            if (!this.recordId) return;

            this.loading = true;

            const services = await listSObjects({
                objectName: 'Service__c',
                fields: [
                    'Id',
                    'Name',
                    'TotalAmount__c',
                    'TotalPaid__c',
                    'Contact__c',
                    'Contact__r.CloverConnectProfileId__c',
                ],
                filters: `AND Id = '${this.recordId}'`
            });

            if (services.length === 0) {
                this.loading = false;
                return;
            }

            this.userFields.serviceId = services[0].Id;
            this.userFields.contactId = services[0].Contact__c;
            this.userFields.payee = this.payee;

            this.service = services.map((service) => {
                return {
                    id:  service.Id,
                    name: service.Name,
                    contactId: service.Contact__c,
                    totalAmount: service.TotalAmount__c,
                    profileId: service.Contact__r.CloverConnectProfileId__c,
                    // TotalPaid__c: service.TotalPaid__c
                }
            })[0];

            this.loading = false;
        } catch (e) {
            this.loading = false;
           console.error('Error: ', e);
        }
    }

    async loadPayments() {
        try {
            if (!this.service) return;

            this.loading = true;

            const payments = await listSObjects({
                objectName: 'Payment__c',
                fields: [
                    'Id',
                    'Name',
                    'Invoice__c',
                    'PaymentDate__c',
                    'PaymentAmount__c',
                    'PaymentMethod__c',
                    'Status__c',
                    'TransactionId__c',
                    'PaymentType__c',
                    'Payee_Type__c',
                    'ParentPayment__c',
                    'ParentPayment__r.Name',
                    'Service__c'
                ],
                filters: `AND Service__c = '${this.service.id}'`
            });

            if (payments.length === 0) {
                this.loading = false;
                return;
            }

            this.payments = payments.map((payment) => {
                return {
                    ...payment,
                    paymentUrl: '/lightning/r/Payment__c/' + payment.Id + '/view',
                    parentPaymentUrl: payment.ParentPayment__c
                        ? '/lightning/r/Payment__c/' + payment.ParentPayment__c + '/view'
                        : '',
                    parentPaymentName: payment.ParentPayment__r?.Name,
                    refundButton: (payment.PaymentType__c === 'Refund' || payment.PaymentAmount__c === 0) ? 'slds-hide' : ''
                }
            });

            this.payments.sort((a, b) => new Date(b.PaymentDate__c) - new Date(a.PaymentDate__c));
            this.loading = false;
        } catch (e) {
            this.loading = false;
            console.error('Error: ', e);
        }
    }

    async handlePaymentMadeSuccessfully(event) {
        console.log('event.detail.amount ', event.detail.amount);
        // this.service.TotalPaid__c = parseFloat(this.service.TotalPaid__c) + parseFloat(event.detail.amount);
        // console.log(' this.service.TotalPaid__c not NAN',  isNaN(parseFloat(this.service.TotalPaid__c)));
        // console.log(' this.service.TotalPaid__c not NAN',  isNaN(parseFloat(event.detail.amount)));
        const eventSuccess = new ShowToastEvent({
            title: 'Success',
            message: 'Payment Made Successfully',
            variant: 'success'
        });

        this.dispatchEvent(eventSuccess);
        await this.saveService();

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId, 
                objectApiName: 'Service__c',    
                actionName: 'view'
            }
        });
    }

    async saveService(totalPaid) {
        console.log('totalPaid ======>', totalPaid);
        try {
            const service = {
                sobjectType: 'Service__c',
                Id: this.service.id,
                // TotalPaid__c: this.service.TotalPaid__c
            };

            console.log('service => ', JSON.stringify(service));

            await saveSObjects({sObjects: [service]});
            await this.loadPayments();
        } catch (e) {
           console.error('Error: ', e);
        }
    }

    async handlePayManually() {
        try {
            this.loading = true;

            const payment = {
                sobjectType: 'Payment__c',
                PaymentAmount__c: this.manualPayment.amount,
                PaymentDate__c: getSfDate(new Date()),
                PaymentMethod__c: this.paymentType,
                PaymentType__c: 'Payment',
                Payee_Type__c: this.payee,
                Service__c: this.service.id,
                Status__c: 'Approved'
            };

            if (this.paymentType === 'Check') {
               payment.CheckNumber__c = this.manualPayment.checkNumber;
            }

            const savedPayment = await saveSObjects({sObjects: [payment]});
            console.log(' payment.PaymentAmount__c ', payment.PaymentAmount__c);
            console.log(' payment.PaymentAmount__c ', isNaN(payment.PaymentAmount__c));
            // this.service.TotalPaid__c = payment.PaymentAmount__c;
            // console.log(' this.service.TotalPaid__c ',  this.service.TotalPaid__c);
            this.manualPayment = {};

            const eventSuccess = new ShowToastEvent({
                title: 'Success',
                message: 'Payment Made Successfully',
                variant: 'success'
            });
            this.dispatchEvent(eventSuccess);

            //await this.savePaymentService(savedPayment[0]);
            await this.saveService();
            this.loading = false;

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId, 
                    objectApiName: 'Service__c', 
                    actionName: 'view'
                }
            });
            
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    async savePaymentService(payment) {
        try {
            console.log('Payment => ', JSON.stringify(payment));
            const paymentService = {
                sobjectType: 'Payment__c',
                Service__c: this.service.id,
                Payment__c: payment.Id,
                Amount__c: payment.PaymentAmount__c
            };

            await saveSObjects({sObjects: [paymentService]});
        } catch (e) {
            console.error('Error: ', e);
        }
    }

    async handleRefundSuccessfully() {
        await this.loadPayments();
    }

    handleChangePaymentType(event) {
        const paymentType = event.target.value;
        if (paymentType === 'CreditCard') {
            this.message = `If no saved cards available, you can enter a new card to the list on "Manage Payment Methods" 
            button.`;
        } else if (paymentType === 'Check') {
            this.message = `We only support business checks or money orders. 
           Please verify that check or money order is made out to "NW Furniture Bank"`;
        } else {
            this.message = '';
        }
        this.paymentType = paymentType;
    }

    handleRefundPayment(event) {
        if (event.detail.row) {
            this.template.querySelector('c-refund-payment').setPayment(event.detail.row);
            this.template.querySelector('c-refund-payment').openModal();
        }
    }

    async handleChangePaymentMethods(event) {
        try {
            this.loading = true;
            const contact = {
                Id: this.service.contactId,
                CloverConnectProfileId__c: event.detail.profileId
            }
            await saveSObjects({sObjects: [contact]});
            this.loading = false;
            this.template.querySelector('c-clover-connect-payment-form').profileId = event.detail.profileId;
            this.template.querySelector('c-clover-connect-payment-form').getAccounts();

        } catch (e) {
            console.error('Error: ', e);
        }
    }

    handleDeleteAccount() {
        this.template.querySelector('c-clover-connect-payment-form').getAccounts();
    }

    async handleDeleteProfile() {
        this.loading = true;
        const contact = {
            Id: this.service.contactId,
            CloverConnectProfileId__c: ''
        }
        await saveSObjects({sObjects: [contact]});
        this.loading = false;
        this.template.querySelector('c-clover-connect-profile-manager').profileId = '';
        this.template.querySelector('c-clover-connect-payment-form').getAccounts();
    }

    handleManagePaymentMethods() {
        this.enableProfileManager = !this.enableProfileManager;
    }

    handleInputChange(event) {
        this.manualPayment[event.target.name] = event.target.value;
    }

    setupTableColumn() {
        this.tableColumn = [
            {
                label: 'Date',
                fieldName: 'paymentUrl',
                type: 'url',
                hideDefaultActions: true,
                typeAttributes: {
                    label: {fieldName: 'PaymentDate__c'},
                    target: '_blank'
                }
            },
            { label: 'Amount', fieldName: 'PaymentAmount__c', type: 'currency', hideDefaultActions: true},
            { label: 'Method', fieldName: 'PaymentMethod__c', type: 'text', hideDefaultActions: true},
            {
                label: 'Action',
                type: 'button',
                typeAttributes: {
                    iconName: 'utility:refresh',
                    label: 'Refund',
                    name: 'refundPayment',
                    title: 'Refund Payment',
                    variant: 'brand-outline',
                    disabled: false,
                    class: {fieldName: 'refundButton'}
                }
            }
        ]
    }

    get managePaymentMethodsButtonLabel() {
        return this.enableProfileManager ? 'Hide Payment Methods Setup' : 'Manage Payment Methods'
    }

    get enableCardForm() {
        return this.service && this.paymentType === 'CreditCard';
    }

    get enableCheckNumberInput() {
       return this.paymentType === 'Check';
    }

    handlePayeeChange(event) {
        this.payee = event.detail.value;
        this.userFields.payee = event.detail.value;
    }

    get disablePaymentManuallyButton() {
        const disableButton = this.paymentType === 'Check'
            ? (this.manualPayment.amount < 1 || !this.manualPayment.amount || !this.manualPayment.checkNumber)
            : (this.manualPayment.amount < 1 || !this.manualPayment.amount);
        return disableButton;
    }
}