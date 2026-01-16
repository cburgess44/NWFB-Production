/**
 * Created by Gustavo on 26/06/23.
 */

import {api, LightningElement, track} from 'lwc';

import listSObjects from '@salesforce/apex/SObjectCRUDController.listSObjects';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';

export default class ProfileManager extends LightningElement {

    loading;

    @track
    contact;

    @api
    recordId;

    constructor() {
        super();
        this.loading = false;
        this.contact = null;
    }

    async connectedCallback() {
        await this.loadContactInformation();
    }

    async loadContactInformation() {
        try {
            this.loading = true;
            const contacts = await listSObjects({
                objectName: 'Contact',
                fields: ['CloverConnectProfileId__c', 'DefaultPaymentMethodToken__c'],
                filters: `AND Id = '${this.recordId}'`
            });

            if (contacts.length === 0) return;

            this.contact = contacts[0];
            this.loading = false;
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    async handleSaveProfile(event) {
        try {
            this.loading = true;

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
            this.loading = false;
            console.error('Error: ', e);
        }
    }

    async handleChangeDefaultProfile(event) {
        try {
            this.loading = true;

            this.contact = {
                ...this.contact,
                DefaultPaymentMethodToken__c: event.detail.token
            };

            await saveSObjects({sObjects: [this.contact]});

            this.loading = false;
        } catch (e) {
            this.loading = false;
            console.error('Error: ', e);
        }
    }
}