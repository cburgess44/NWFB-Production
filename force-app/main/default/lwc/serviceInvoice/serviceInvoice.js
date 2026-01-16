/*
 * Created by Eric on 15/06/2023.
 */

import { LightningElement, api, track } from 'lwc';
import listSObjects from '@salesforce/apex/SObjectCRUDController.listSObjects';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import generateInvoice from '@salesforce/apex/ServiceDao.callGenerateInvoiceAndSendPDF';

export default class ServiceInvoice extends LightningElement {
    @api
    recordId;

    @track
    showCaseworker;

    @track
    showContact;

    @track
    showAPContact;

    @track
    showSendButton;

    @track
    isLoaded;

    service;
    contactEmailSelected;
    caseWorkerEmailSelected;
    apContactsSelected;

    constructor() {
        super();
        this.init();
    }

    init() {
        this.showCaseworker = false;
        this.showContact = false;
        this.showAPContact = false;
        this.showSendButton = false;
        this.isLoaded = true;
        this.service = {};
        this.contactEmailSelected = false;
        this.caseWorkerEmailSelected = false;
        this.apContactsSelected = false;
    }

    async connectedCallback() {
        await this.fetchData();
    }

    // async getAPContacts(){
    //     const filter = `AND Case_Worker__c = '${this.service.Caseworker__c}' `;
    //
    //     const contacts = await listSObjects({
    //         objectName: 'AP_Contact__c',
    //         fields: [
    //             'Id',
    //             'Name'
    //         ],
    //         filters: filter
    //     });
    //
    //     if (contacts === null) return;
    //
    //     this.agencyContacts = contacts;
    //     this.showAPContact = this.agencyContacts !== null;
    // }

    async fetchData(){
        const filter = `AND Id = '${this.recordId}' `;

        const service = await listSObjects({
            objectName: 'Service__c',
            fields: [
                'Id',
                'Contact__c',
                'Agency__c',
                'Caseworker__c',
                'Contact__r.HasEmail__c',
                'Caseworker__r.HasEmail__c',
                'Caseworker__r.AP_Contact_Email__c'
            ],
            filters: filter
        });

        if (service === null) return;

        this.service = service[0];

        if (this.service.Contact__c) this.showContact = this.service.Contact__r.HasEmail__c;
        if (this.service.Caseworker__c) this.showCaseworker = this.service.Caseworker__r.HasEmail__c;
        if (this.service.Caseworker__c && this.service.Caseworker__r.AP_Contact_Email__c) this.showAPContact = true;

        // await this.getAPContacts();
    }

    handleCheckBoxChange(event) {
        const value = event.target.checked;
        const contactType = event.target.dataset.targetId;

        if (contactType === 'caseworker') {
            this.caseWorkerEmailSelected = value;
        } else if (contactType === 'contact' ) {
            this.contactEmailSelected = value;
        } else if (contactType === 'apContact' ) {
            this.apContactsSelected = value;
        }
    }

    async handleSendEmail(){
        this.isLoaded = false;

        const emailResult = await generateInvoice({
            serviceId: this.service.Id,
            sendToCaseWorker: this.caseWorkerEmailSelected,
            sendToContact: this.contactEmailSelected,
            sendToAPContacts: this.apContactsSelected
        });

        if (emailResult === 'SentEmails') {
            let message = 'The invoices was generated successfully';

            if (this.caseWorkerEmailSelected || this.contactEmailSelected || this.apContactsSelected) {
                message = 'The Invoice was generated and the emails sent successfully';
            }

            this.showToast(
                'Generate Invoices',
                message,
                'success'
            );

            setTimeout(() => {
                window.location.reload();
            }, 1500);
        } else {
            this.showToast(
                'Error',
                emailResult,
                'error'
            );
            this.isLoaded = true;
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            Title: title,
            message: message,
            variant: variant,
            mode: 'dismissible',
        }));
    }

    get sendButtonLabel() {
       return (this.caseWorkerEmailSelected || this.contactEmailSelected || this.apContactsSelected)
            ? 'Generate Invoice and Notify'
            : 'Generate Invoice without Notifications';
    }
}