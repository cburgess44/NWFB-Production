import { LightningElement, wire, api } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import AGREEMENT_TEXT from '@salesforce/schema/Service__c.AgreementText__c';

export default class AgreementComponent extends LightningElement {
    @api recordId;
    @wire(getRecord, { recordId: '$recordId', fields: [AGREEMENT_TEXT] })
    request

    get agreementText() {
        return getFieldValue(this.request.data, AGREEMENT_TEXT);
    }
}