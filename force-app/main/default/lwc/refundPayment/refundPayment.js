/**
 * Created by Gustavo on 23/06/23.
 */

import {api, LightningElement, track} from 'lwc';

import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';
import refundPayment from '@salesforce/apex/CloverConnectController.refund';
import getMerchantId from '@salesforce/apex/CloverConnectController.getMerchantId';

import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class RefundPayment extends LightningElement {

    @api
    payment;

    @api
    enableModal;

    @track
    paymentRefund;

    @track
    merchantSetting = 'MerchantSetting';

    loading;
    merchId;

    constructor() {
        super();
        this.init();
    }

    async connectedCallback() {
        await this.setMerchant();
        this.paymentRefund.PaymentAmount__c = this.payment?.PaymentAmount__c;
    }

    init() {
        this.paymentRefund = {};
    }

    handleCancel() {
        this.enableModal = false;
        this.paymentRefund = {};
    }

    async setMerchant() {
        try {
            this.merchId = await getMerchantId({
                settingDeveloperName: this.merchantSetting
            });
        } catch (e) {
            console.error('Error: ', e);
        }
    }

    async handleSubmitRefund() {
        try {
            this.loading = true;

            this.paymentRefund = {
                ...this.paymentRefund,
                sobjectType: 'Payment__c',
                PaymentMethod__c: this.payment.PaymentMethod__c,
                PaymentDate__c: new Date(),
                Status__c: 'Approved',
                Service__c: this.payment.Service__c,
                PaymentType__c: 'Refund',
                ParentPayment__c: this.payment.Id,
            }

            if (this.payment.PaymentMethod__c === 'CreditCard') {
                await refundPayment({
                    refundJSON: JSON.stringify({
                        retref: this.payment.TransactionId__c,
                        merchid: this.merchId,
                        amount: Math.abs(this.payment.PaymentAmount__c)
                    })
                });
            }

            this.payment.PaymentAmount__c = (this.payment.PaymentAmount__c - this.paymentRefund.PaymentAmount__c);
            await saveSObjects({sObjects: [this.paymentRefund, this.payment]});
            await this.saveNote();

            const eventSuccess = new ShowToastEvent({
                title: 'Success',
                message: 'Payment Refunded Successfully',
                variant: 'success'
            });

            this.dispatchEvent(eventSuccess);
            this.dispatchEvent(new CustomEvent('afterrefund'));
            this.paymentRefund = {};
            this.enableModal = false;
            this.loading = false;
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    handleInputChange(event) {
        this.paymentRefund[event.target.name] = event.target.value;
    }

    async handleVoidPayment() {
        try {
            this.loading = true;
            this.payment.PaymentAmount__c = 0;
            this.payment.Status__c = 'Voided';

            if (this.payment.PaymentMethod__c === 'CreditCard') {
                await refundPayment({
                    refundJSON: JSON.stringify({
                        retref: this.payment.TransactionId__c,
                        merchid: this.merchId,
                        amount: Math.abs(this.payment.PaymentAmount__c)
                    })
                });
            }

            await saveSObjects({sObjects: [this.payment]});
            await this.saveNote();

            const eventSuccess = new ShowToastEvent({
                title: 'Success',
                message: 'Payment Voided Successfully',
                variant: 'success'
            });
            this.dispatchEvent(new CustomEvent('afterrefund'));

            this.dispatchEvent(eventSuccess);
            this.enableModal = false;
            this.loading = false;
        } catch (e) {
            console.error('Error: ', e);
        }
    }

    async saveNote() {
        try {
            const note = {
                sobjectType: 'Note',
                ParentId: this.payment.Service__c,
                Title: 'Refund Reason',
                Body: this.paymentRefund.reasonForRefund
            };

            await saveSObjects({sObjects: [note]});
        } catch (e) {
            console.error('Error: ', e);
        }
    }

    @api
    setPayment (payment) {
        this.payment = payment;
    }

    @api
    openModal() {
        this.enableModal = true;
    }

    get enableSubmitPaymentButton() {
        let paymentDate = new Date(this.payment.PaymentDate__c).getTimezoneOffset();
        paymentDate = new Date(new Date(this.payment.PaymentDate__c).getTime() + (paymentDate * 60 * 1000));
        paymentDate.setHours(0, 0, 0, 0);

        const currentDate = new Date();
        currentDate.setHours(0, 0, 0, 0);

        return currentDate > paymentDate;
    }

    get disableSubmitButton() {
        return (this.payment.PaymentMethod__c !== 'CreditCard' && !this.paymentRefund.PaymentAmount__c)
            || this.loading || !this.paymentRefund?.reasonForRefund;
    }

    get paymentMadeByCreditCard() {
        return this.payment.PaymentMethod__c === 'CreditCard';
    }

}