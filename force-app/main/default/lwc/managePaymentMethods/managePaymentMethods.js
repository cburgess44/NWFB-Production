/**
 * Created by Gustavo on 07/03/24.
 */

import {LightningElement, track, api} from 'lwc';

import listSObjects from '@salesforce/apex/SObjectCRUDController.listSObjects';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';

export default class ManagePaymentMethods extends LightningElement {

    @api
    recordId;

    @track
    recurringDonation;

    @track
    contact;

    @track
    dataLoadedSuccessfully;

    loading;

    constructor() {
        super();
        this.recurringDonation = {};
        this.dataLoadedSuccessfully = false;
        this.contact = {};
        this.loading = false;
    }

    async connectedCallback() {
        await this.init();
    }

    async init() {
        this.loading = true;
        await this.loadRecurringDonation();
        await this.loadContact();
        this.dataLoadedSuccessfully = true;
        this.loading = false;
    }

    async loadRecurringDonation() {
        if (!this.recordId) return;

        try {
            const recurringDonations = await listSObjects({
                objectName: 'npe03__Recurring_Donation__c',
                fields: [
                    'Id',
                    'npe03__Contact__c',
                    'PaymentToken__c'
                ],
                filters: `AND Id = '${this.recordId}'`
            });

            if (recurringDonations.length === 0) return;

            this.recurringDonation = recurringDonations[0];

        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }

    }

    async loadContact() {
        try {
            if (!this.recurringDonation) return;

            const contacts = await listSObjects({
                objectName: 'Contact',
                fields: [
                    'Id',
                    'Name',
                    'CloverConnectProfileId__c',
                    'DefaultPaymentMethodToken__c'
                ],
                filters: `AND Id = '${this.recurringDonation.npe03__Contact__c}'`
            });

            if (contacts.length === 0) return;

            this.contact = contacts[0];
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    async handleSaveProfile(event) {
        try {
            if (!event.detail.profileId) return;
            this.loading = true;
            console.log('token => ' + event.detail.token);

            this.contact = {
                ...this.contact,
                CloverConnectProfileId__c: event.detail.profileId,
                DefaultPaymentMethodToken__c: event.detail.token
                    ? event.detail.token
                    : this.contact.DefaultPaymentMethodToken__c
            };

            await saveSObjects({sObjects: [this.contact]});

            this.loading = false;
        } catch (e) {
            console.error('Error ' + JSON.stringify(e));
            this.loading = false
        }
    }

    async handleChangeDefaultMethod(event) {
        try {
            this.loading = true;
            this.contact.DefaultPaymentMethodToken__c = event.detail.token;
            await saveSObjects({sObjects: [this.contact]});
            this.loading = false;
        } catch (e) {
            console.error('Error: ' + e);
            this.loading = false;
        }

    }
}