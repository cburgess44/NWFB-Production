import { LightningElement, api, track } from 'lwc';
import listSobjects from '@salesforce/apex/SObjectCRUDController.listSObjects';

export default class CustomRecordDetails extends LightningElement {
    
    recordFields = [
        { label: 'Sub Total', fieldName: 'SubTotal__c', type: 'currency' },
        { label: 'Delivery Fee', fieldName: 'Delivery_Fee__c', type: 'currency' },
        { label: 'Proceessing Fee', fieldName: 'Processing_Fee__c', type: 'currency' },
        { label: 'Pickup Fee', fieldName: 'Pickup_Fee__c', type: 'currency' },
        { label: 'Tax', fieldName: 'TaxAmount__c', type: 'currency' },
        { label: 'Total', fieldName: 'Total__c', type: 'currency' }
    ];

    @api 
    recordId;
    @api 
    objectApiName;

    @track
    records;
    // @track
    // doNotShow = false;

    async connectedCallback(){
        if(this.objectApiName === 'Service__c'){
            await this.getServiceById();

        }else if(this.objectApiName === 'Invoice__c'){
            console.log('INVOICE PART');
            await this.getInvoiceById();
        }
        
    }  

    async getServiceById() {

        const filter = `AND Id = '${this.recordId}' `;

        const service = await listSobjects({
            objectName: 'Service__c',
            fields: [
                'Id',
                'SubTotal__c',
                'Delivery_Fee__c',
                'Processing_Fee__c',
                'Pickup_Fee__c',
                'TaxAmount__c',
                'Total__c',
            ],
            filters: filter
        });
        console.log('service ', service);

        if (service === null) return;

        this.records = service;
    }

    async getInvoiceById() {
        
        const filter = `AND Id = '${this.recordId}' `;

        const invoice = await listSobjects({
            objectName: 'Invoice__c',
            fields: [
                'Id',
                'Request__r.Delivery_Fee__c',
                'Request__r.Processing_Fee__c',
                'Request__r.TaxAmount__c',
                'Request__r.Total__c',
                'Request__r.SubTotal__c',
                'Request__r.Pickup_Fee__c',
            ],
            filters: filter
        });
        console.log('invoice ', invoice);

        if (invoice === null) return;

        let formattedObjectList = [];

        for(let inv of invoice){

            const formattedObject = {
                Id : inv.Id,
                SubTotal__c : inv.Request__r.SubTotal__c,
                Delivery_Fee__c : inv.Request__r.Delivery_Fee__c,
                Processing_Fee__c : inv.Request__r.Processing_Fee__c,
                Pickup_Fee__c : inv.Request__r.Pickup_Fee__c,
                TaxAmount__c : inv.Request__r.TaxAmount__c,
                Total__c : inv.Request__r.Total__c
            }

            formattedObjectList.push(formattedObject);
        }
        
        for(let inv of invoice){
            if(inv.Request__r.Delivery_Fee__c === 0 || inv.Request__r.Processing_Fee__c === 0 || inv.Request__r.TaxAmount__c === 0  || inv.Request__r.Pickup_Fee__c === 0 ){
                this.doNotShow = true;
                continue;
            }
        }

        this.records = formattedObjectList;
    }
}