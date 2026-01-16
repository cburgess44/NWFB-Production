/**
 * Created by Gustavo on 21/06/2022.
 */

import {api, LightningElement, wire} from 'lwc';
import {formLabels} from './constants';
import {getRecord} from 'lightning/uiRecordApi';

export default class CloverConnectPayloadFields extends LightningElement {

    @api
    recordId;

    label = formLabels;

    payloadFields;

    userFields;

    @wire(getRecord,({recordId: '$recordId', fields: ['CloverConnectLog__c.Payload__c']}))
    wireCloverConnectLog({ error, data }) {
        if (data) {
            const fields = JSON.parse(data.fields.Payload__c.value);
            const userFields =  fields.userfields;

            this.payloadFields = Object.keys(fields).filter(field => field !== 'userfields').map((field) => {
                return {
                    label: field,
                    value: fields[field],
                    isCheckboxField: typeof fields[field] === 'boolean'
                }
            });

            if (userFields) {
                this.userFields = Object.keys(userFields).map((userField) => {
                    return {
                        label: userField,
                        value: userFields[userField],
                        isCheckboxField: typeof userFields[userField] === 'boolean'
                    }
                });
            }

        } else if (error) {
            console.error('Error: ', error);
        }
    }

    renderedCallback() {
        const styleDisabled = document.createElement('style');
        styleDisabled.innerText = `.custom-content .slds-input {
                background: #f9f9f900 !important;
                border: none !important;
                border-radius: 0 !important;
                padding-left: 10px !important;
                border-bottom: 1px solid #ccc !important;
            }`;

        this.template.querySelectorAll('lightning-input').forEach((element) => {
            element.appendChild(styleDisabled);
        });
    }

}