/**
 * Created by Alan Arantes Souza on 30/07/2020.
 */

import {LightningElement, api, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import listSObjects from '@salesforce/apex/SObjectCRUDController.listSObjects';

export default class LookupInput extends LightningElement {
    typingTimeout;

    @track isLoading = false;

    @track isExpanded = false;

    @track records = [];

    @track selectedRecord;

    @api fieldName;

    @api disabled = false;

    @api required = false;

    @api topLabel;

    @api label;

    @api placeholder;

    @api spinnerInResultList;

    @api sObjectName;

    @api searchField = 'Name';

    @api searchTerm;

    @api value;

    @api whereClause = '';

    @api fieldNames = ['Id', 'Name'];

    @api showExtraFieldNames;

    @api extraFieldNames = [];

    @api customStyle;

    @api name;

    @api
    setValueById(Id) {
        listSObjects({
            objectName: this.sObjectName,
            fields: ['Name'],
            filters: `AND Id = '${Id}'`
        })
            .then(result => {
                if (result && result.length > 0) {
                    this.searchTerm = result[0].Name;
                }
            })
            .catch(error => {
                this.isExpanded = false;
                const eventError = new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error'
                });
                this.dispatchEvent(eventError);
            });

    }

    @api
    validate() {
        const isAllGood = [...this.template.querySelectorAll('lightning-input')].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            let isValid = inputCmp.value !== null && inputCmp.value !== '' && inputCmp.value !== undefined;
            if (!isValid) {
                this.generateInputCustomError('Complete this field.');
                this.dispatchEvent(new CustomEvent("clear", {
                    detail: {
                        fieldName: this.fieldName
                    }
                }));
            }
            return validSoFar && inputCmp.checkValidity() && isValid;
        }, true);

        return isAllGood
    }

    connectedCallback() {
        if (this.value) this.setValueById(this.value);
    }

    renderedCallback() {
        if (!this.label)
            this.template.querySelector(`[data-id='${this.fieldName}']`).classList.add('no-label');

        // const style = document.createElement('style');
        // style.innerText = `.slds-form-element__label { display: none }`;
        // this.template.querySelector('lightning-input').appendChild(style);
    }

    get containerStyle() {
        let classes = 'slds-form-element slds-lookup';

        if (this.customStyle) classes += ' ' + this.customStyle;
        if (this.isExpanded) classes += ' slds-is-open';

        return classes;
    }

    get inputPlaceholder() {
        let placeholder = this.placeholder;

        if (!this.placeholder)
            placeholder = 'Search ' + this.sObjectName.replace(/BP_|__c/gi, '') + ' ... '

        return placeholder;
    }

    get inputSpinner() {
        return this.isLoading && !this.spinnerInResultList;
    }

    get requiredFieldMessage() {
        let error = (this.label != null) ? this.label : this.topLabel;
        return `${error} is a required field`;
    }

    handleInputChange(event) {
        this.searchTerm = event.target.value;
        if (this.typingTimeout)
            clearTimeout(this.typingTimeout);
        if (this.searchTerm.length < 2) {
            //WorkArround to remove error if exists
            this.generateInputCustomError('');

            this.isLoading = false;
            this.isExpanded = false;
            return;
        } else {
            this.isLoading = true;
        }

        const self = this;
        this.typingTimeout = setTimeout(function () {
            if (self.sObjectName === 'User.CodeCountry') self.getStateAndCountryValues();
            else self.searchRecords();

        }, 666);
    }

    handleInputOnBlur(event) {
        this.searchTerm = event.target.value;
        if (!this.searchTerm.length) {
            this.generateInputCustomError('Complete this field');
            this.dispatchEvent(new CustomEvent("clear", {
                detail: {
                    fieldName: this.fieldName
                }
            }));
        }
    }

    handleSelectedRecord(event) {
        const obj = this.records.find(obj => obj.Id === event.target.dataset.id);

        if (obj) {
            this.isExpanded = false;
            this.selectedRecord = obj;
            this.searchTerm = obj.Name;

            const selectedRecordEvent = new CustomEvent("recordselected", {
                detail: {
                    fieldName: this.fieldName,
                    fieldValue: this.selectedRecord,
                    value: this.selectedRecord.Id,
                    name: this.name
                }
            });

            this.dispatchEvent(selectedRecordEvent);
        }
    }

    searchRecords() {
        this.isExpanded = true;
        this.records = [];
        const whereClause = 'AND ' + this.searchField + ' LIKE \'%' + this.searchTerm + '%\' ' + this.whereClause;
        const self = this;
        listSObjects({
            objectName: this.sObjectName, fields: this.fieldNames, filters: whereClause,
            disableSharingRules: false

        })
            .then(result => {
                if (result && result.length > 0) {
                    if (this.showExtraFieldNames) {
                        if (this.extraFieldNames) {
                            result.forEach(function (r) {
                                r.description = ' (';


                                self.extraFieldNames.forEach(function (f, i) {
                                    r.description += i === self.extraFieldNames.length - 1
                                        ? r[f] + ')'
                                        : r[f] + ', ';
                                });
                            });

                        }
                    }

                    this.records = result;
                } else {
                    this.isExpanded = false;
                    this.generateInputCustomError('No results found.');
                }
            })

            .catch(error => {
                this.isExpanded = false;
                const eventError = new ShowToastEvent({
                    title: 'Error',
                    message: error,
                    variant: 'error'
                });
                this.dispatchEvent(eventError);

            })
            .finally(() => {
                this.isLoading = false;
            });
    }


    generateInputCustomError(error) {
        const input = this.template.querySelector(`[data-id='${this.fieldName}']`);
        input.setCustomValidity(error);
        input.reportValidity();
    }

    @api
    checkValidity() {
        const input = this.template.querySelector(`[data-id='${this.fieldName}']`);
        return input.checkValidity();
    }

    @api
    reportValidity() {
        const input = this.template.querySelector(`[data-id='${this.fieldName}']`);
        input.reportValidity();
    }

}