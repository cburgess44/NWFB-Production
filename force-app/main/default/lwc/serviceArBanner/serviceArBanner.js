import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

// Use optionalFields to prevent errors if fields don't exist
const OPTIONAL_FIELDS = [
    'Service__c.BalanceDue__c',
    'Service__c.ARAgingBucket__c',
    'Service__c.DaysOutstanding__c',
    'Service__c.CollectionsStatus__c',
    'Service__c.WriteOffDate__c',
    'Service__c.WriteOffReason__c',
    'Service__c.WriteOffAmount__c'
];

export default class ServiceArBanner extends LightningElement {
    @api recordId;

    @wire(getRecord, { recordId: '$recordId', optionalFields: OPTIONAL_FIELDS })
    wiredService({ error, data }) {
        if (data) {
            this.service = { data };
        } else if (error) {
            // Silently fail - just hide the banner
            this.service = undefined;
            console.warn('ServiceArBanner: Could not load record data');
        }
    }

    service;

    getFieldValue(fieldName) {
        if (!this.service || !this.service.data || !this.service.data.fields) return null;
        const field = this.service.data.fields[fieldName];
        return field ? field.value : null;
    }

    get balanceDue() {
        return this.getFieldValue('BalanceDue__c') || 0;
    }

    get arAgingBucket() {
        return this.getFieldValue('ARAgingBucket__c') || '';
    }

    get daysOutstanding() {
        return this.getFieldValue('DaysOutstanding__c');
    }

    get collectionsStatus() {
        return this.getFieldValue('CollectionsStatus__c') || '';
    }

    get writeOffDate() {
        return this.getFieldValue('WriteOffDate__c');
    }

    get writeOffReason() {
        return this.getFieldValue('WriteOffReason__c') || '';
    }

    get writeOffAmount() {
        return this.getFieldValue('WriteOffAmount__c') || 0;
    }

    get isWrittenOff() {
        return this.collectionsStatus === 'Written Off';
    }

    get isPaid() {
        return this.balanceDue <= 0 && !this.isWrittenOff;
    }

    get showBanner() {
        // Show banner if there's a balance due OR if written off
        // Hide if fully paid and not written off
        if (!this.service || !this.service.data) return false;
        return this.balanceDue > 0 || this.isWrittenOff;
    }

    get showAmount() {
        return this.balanceDue > 0;
    }

    get showDaysOutstanding() {
        return this.daysOutstanding && this.daysOutstanding > 0 && !this.isWrittenOff;
    }

    get formattedBalance() {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(this.balanceDue);
    }

    get formattedWriteOffDate() {
        if (!this.writeOffDate) return '';
        return new Date(this.writeOffDate).toLocaleDateString('en-US', {
            month: 'short',
            day: 'numeric',
            year: 'numeric'
        });
    }

    get statusText() {
        if (this.isWrittenOff) {
            return 'Written Off';
        }

        switch (this.arAgingBucket) {
            case '90+ Days':
                return '90+ Days Overdue';
            case '61-90 Days':
                return '61-90 Days Overdue';
            case '31-60 Days':
                return '31-60 Days Overdue';
            case 'Current (0-30 Days)':
                return 'Payment Due';
            case 'No Service Date':
                return 'Balance Due';
            default:
                return 'Balance Due';
        }
    }

    get formattedWriteOffAmount() {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD'
        }).format(this.writeOffAmount);
    }

    get iconName() {
        if (this.isWrittenOff) {
            return 'utility:ban';
        }
        // Use clock icon for all overdue states
        return 'utility:clock';
    }

    get bannerClass() {
        let baseClass = 'ar-banner';
        
        if (this.isWrittenOff) {
            return baseClass + ' banner-written-off';
        }

        switch (this.arAgingBucket) {
            case '90+ Days':
                return baseClass + ' banner-90-plus';
            case '61-90 Days':
                return baseClass + ' banner-61-90';
            case '31-60 Days':
                return baseClass + ' banner-31-60';
            case 'Current (0-30 Days)':
                return baseClass + ' banner-current';
            default:
                return baseClass + ' banner-default';
        }
    }
}
