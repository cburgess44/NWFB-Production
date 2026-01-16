/**
 * Created by Gustavo on 14/02/24.
 */

import {LightningElement, track} from 'lwc';

import listSObjects from '@salesforce/apex/SObjectCRUDController.listSObjects'
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects'

import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {CloseActionScreenEvent} from 'lightning/actions';

export default class CloneService extends LightningElement {

    @track
    service;

    loading;
    serviceId;

    constructor() {
        super();
        this.service = {};
    }

    async connectedCallback() {
        await this.init();
    }

    async init() {
        const urlSearchParams = new URLSearchParams(window.location.search);
        this.serviceId = urlSearchParams.get('recordId');

        this.loading = true;
        await this.loadService();
        await this.loadServiceItems();
        this.loading = false;
    }

    async loadService() {
        try {
            const services = await listSObjects({
                objectName: 'Service__c',
                fields: [
                    'Id',
                    'Contact__c',
                    'Caseworker__c',
                    'RecordTypeId',
                    'RecordType.Name'
                ],
                filters: `AND Id = '${this.serviceId}'`
            });

            if (!services || services.length === 0) return;

            services[0].recordTypeName = services[0].RecordType.Name;
            this.service = services[0];
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    async loadServiceItems() {
        try {
            const serviceItems = await listSObjects({
                objectName: 'ServiceItem__c',
                fields: [
                    'Id',
                    'TotalItemPrice__c',
                    'Pickup__c',
                    'Product__c',
                    'Quantity_Requested__c',
                    'Status__c',
                    'TaxableItem__c',
                    'Description__c',
                    'ItemCost__c',
                    'ItemNotes__c',
                    'Override_Product_Fee__c',
                    'ItemPhotoURL__c',
                    'ItemPhotoBaseURL__c'
                ],
                filters: `AND Service__c = '${this.service.Id}'`
            });

            if (!serviceItems || serviceItems.length === 0) return;

            this.serviceItems = serviceItems;
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    async handleSubmit(event) {
        event.preventDefault();
        this.loading = true;
        const clonedService = this.buildService(event.detail.fields);
        const savedService = await this.saveClonedService(clonedService);

        if (!savedService || savedService.length === 0) return;
        await this.cloneAndSaveServiceItems(savedService[0].Id);
    }

    buildService(clonedService) {
        Object.keys(clonedService).forEach(key => {
            if (clonedService[key] === null) {
                delete clonedService[key];
            }
        });

        delete clonedService.Id;

        clonedService.sobjectType = 'Service__c';
        clonedService.RecordTypeId = this.service.RecordTypeId;
        return clonedService;
    }

    async cloneAndSaveServiceItems(serviceId) {
        try {
            this.buildServiceItems(serviceId);
            await saveSObjects({sObjects: this.serviceItems});
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'Service Created Successfully',
                variant: 'success',
                mode: 'dismissible'
            }));
            window.location = window.location.origin + `/lightning/r/Service__c/${serviceId}/view`;
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    buildServiceItems(serviceId) {
        this.serviceItems.forEach((serviceItem => {
            Object.keys(serviceItem).forEach(key => {
                if (serviceItem[key] === null) {
                    delete serviceItem[key];
                }
            });
            delete serviceItem.Id;
            serviceItem.sobjectType = 'ServiceItem__c';
            serviceItem.Service__c = serviceId;
        }));
    }

    async saveClonedService(clonedService) {
        try {
            return await saveSObjects({sObjects: [clonedService]});
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    handleCancel() {
        this.dispatchEvent(new CloseActionScreenEvent());
    }
}