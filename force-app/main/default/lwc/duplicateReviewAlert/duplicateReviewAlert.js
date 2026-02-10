import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';
import getMatchingServices from '@salesforce/apex/DuplicateReviewController.getMatchingServices';

import PENDING_DUPLICATE_REVIEW_FIELD from '@salesforce/schema/Service__c.Pending_Duplicate_Review__c';
import DUPLICATE_MATCH_SERVICE_FIELD from '@salesforce/schema/Service__c.Duplicate_Match_Service__c';
import DUPLICATE_REVIEW_NOTES_FIELD from '@salesforce/schema/Service__c.Duplicate_Review_Notes__c';
import DUPLICATE_REVIEW_CLEARED_BY_FIELD from '@salesforce/schema/Service__c.Duplicate_Review_Cleared_By__c';
import DUPLICATE_REVIEW_CLEARED_DATE_FIELD from '@salesforce/schema/Service__c.Duplicate_Review_Cleared_Date__c';

const FIELDS = [
    PENDING_DUPLICATE_REVIEW_FIELD,
    DUPLICATE_MATCH_SERVICE_FIELD,
    DUPLICATE_REVIEW_NOTES_FIELD,
    DUPLICATE_REVIEW_CLEARED_BY_FIELD,
    DUPLICATE_REVIEW_CLEARED_DATE_FIELD,
    'Service__c.Duplicate_Review_Cleared_By__r.Name'
];

export default class DuplicateReviewAlert extends NavigationMixin(LightningElement) {
    @api recordId;
    
    pendingReview = false;
    duplicateServiceId = null;
    reviewNotes = null;
    clearedById = null;
    clearedByName = null;
    clearedDate = null;
    @track showDetails = false;
    @track matchingServices = [];

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.pendingReview = getFieldValue(data, PENDING_DUPLICATE_REVIEW_FIELD);
            this.duplicateServiceId = getFieldValue(data, DUPLICATE_MATCH_SERVICE_FIELD);
            this.reviewNotes = getFieldValue(data, DUPLICATE_REVIEW_NOTES_FIELD);
            this.clearedById = getFieldValue(data, DUPLICATE_REVIEW_CLEARED_BY_FIELD);
            this.clearedDate = getFieldValue(data, DUPLICATE_REVIEW_CLEARED_DATE_FIELD);
            
            // Get cleared by name
            if (data.fields.Duplicate_Review_Cleared_By__r?.value) {
                this.clearedByName = data.fields.Duplicate_Review_Cleared_By__r.value.fields.Name.value;
            }
        } else if (error) {
            console.error('Error loading record:', error);
        }
    }

    @wire(getMatchingServices, { serviceId: '$recordId' })
    wiredMatchingServices({ error, data }) {
        if (data) {
            this.matchingServices = data.map(service => ({
                ...service,
                formattedDate: this.formatDate(service.CreatedDate),
                url: '/' + service.Id
            }));
        } else if (error) {
            console.error('Error loading matching services:', error);
            this.matchingServices = [];
        }
    }

    formatDate(dateString) {
        if (!dateString) return '';
        const date = new Date(dateString);
        return date.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric' 
        });
    }

    get showAlert() {
        return this.pendingReview === true;
    }

    get showCleared() {
        return this.pendingReview === false && this.clearedDate !== null;
    }

    get matchCount() {
        return this.matchingServices.length;
    }

    get hasMultipleMatches() {
        return this.matchingServices.length > 1;
    }

    get clearedDateFormatted() {
        if (!this.clearedDate) return '';
        const date = new Date(this.clearedDate);
        return date.toLocaleDateString('en-US', { 
            year: 'numeric', 
            month: 'short', 
            day: 'numeric' 
        });
    }

    toggleDetails() {
        this.showDetails = !this.showDetails;
    }

    handleViewService(event) {
        const serviceId = event.currentTarget.dataset.id;
        if (serviceId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: serviceId,
                    objectApiName: 'Service__c',
                    actionName: 'view'
                }
            });
        }
    }

    handleClearFlag(event) {
        event.preventDefault();
        
        const notesField = this.template.querySelector('lightning-input-field[field-name="Duplicate_Review_Notes__c"]');
        const notesValue = notesField ? notesField.value : '';

        const fields = {
            Id: this.recordId,
            Pending_Duplicate_Review__c: false,
            Duplicate_Review_Notes__c: notesValue
        };

        updateRecord({ fields })
            .then(() => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Duplicate review flag cleared. Request can now proceed.',
                        variant: 'success'
                    })
                );
                eval("$A.get('e.force:refreshView').fire();");
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body?.message || 'Error clearing flag',
                        variant: 'error'
                    })
                );
            });
    }

    handleSuccess() {
        // This fires after a successful form submission
    }
}
