import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import TOTAL_OUTSTANDING_BALANCE from '@salesforce/schema/Account.TotalOutstandingBalance__c';
import NUMBER_OF_UNPAID_SERVICES from '@salesforce/schema/Account.NumberOfUnpaidServices__c';
import OLDEST_UNPAID_SERVICE_DATE from '@salesforce/schema/Account.OldestUnpaidServiceDate__c';
import ACTIVE from '@salesforce/schema/Account.Active__c';
import INACTIVE from '@salesforce/schema/Account.Inactive__c';

const FIELDS = [TOTAL_OUTSTANDING_BALANCE, NUMBER_OF_UNPAID_SERVICES, OLDEST_UNPAID_SERVICE_DATE, ACTIVE, INACTIVE];

export default class AgencyArBanner extends LightningElement {
    @api recordId;
    
    totalOutstandingBalance;
    numberOfUnpaidServices;
    oldestUnpaidServiceDate;
    active;
    inactive;
    
    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredRecord({ error, data }) {
        if (data) {
            this.totalOutstandingBalance = getFieldValue(data, TOTAL_OUTSTANDING_BALANCE);
            this.numberOfUnpaidServices = getFieldValue(data, NUMBER_OF_UNPAID_SERVICES);
            this.oldestUnpaidServiceDate = getFieldValue(data, OLDEST_UNPAID_SERVICE_DATE);
            this.active = getFieldValue(data, ACTIVE);
            this.inactive = getFieldValue(data, INACTIVE);
        }
    }
    
    get showBanner() {
        // Show banner if not active OR has outstanding balance
        return this.active === false || (this.totalOutstandingBalance && this.totalOutstandingBalance > 0);
    }
    
    get isInactive() {
        // Now based on Active field (Active = false means inactive)
        return this.active === false;
    }
    
    get hasBalance() {
        return !this.isInactive && this.totalOutstandingBalance > 0;
    }
    
    get formattedBalance() {
        return new Intl.NumberFormat('en-US', { 
            style: 'currency', 
            currency: 'USD' 
        }).format(this.totalOutstandingBalance || 0);
    }
    
    get daysOutstanding() {
        if (!this.oldestUnpaidServiceDate) return 0;
        const oldest = new Date(this.oldestUnpaidServiceDate);
        const today = new Date();
        const diffTime = today - oldest;
        const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
        return diffDays;
    }
    
    get agingBucket() {
        const days = this.daysOutstanding;
        if (days >= 90) return '90+ Days';
        if (days >= 61) return '61-90 Days';
        if (days >= 31) return '31-60 Days';
        return 'Current (0-30 Days)';
    }
    
    get isCritical() {
        // RED: 90+ days overdue OR balance > $1500
        return this.daysOutstanding >= 90 || this.totalOutstandingBalance > 1500;
    }

    get isWarning() {
        // ORANGE: 61-90 days overdue OR balance >= $1000
        return !this.isCritical && (this.daysOutstanding >= 61 || this.totalOutstandingBalance >= 1000);
    }

    get isCaution() {
        // YELLOW: 31-60 days overdue OR balance >= $500
        return !this.isCritical && !this.isWarning && (this.daysOutstanding >= 31 || this.totalOutstandingBalance >= 500);
    }

    get bannerClass() {
        let baseClass = 'ar-banner slds-p-around_small slds-grid slds-grid_vertical-align-center';
        
        if (this.isInactive) {
            return baseClass + ' banner-inactive';
        }
        
        if (this.isCritical) {
            return baseClass + ' banner-critical';
        }
        if (this.isWarning) {
            return baseClass + ' banner-warning';
        }
        if (this.isCaution) {
            return baseClass + ' banner-caution';
        }
        if (this.totalOutstandingBalance > 0) {
            return baseClass + ' banner-current';
        }
        return baseClass;
    }
    
    get iconName() {
        if (this.isInactive) {
            return 'utility:ban';
        }
        if (this.isCritical) {
            return 'utility:error';
        }
        if (this.isWarning || this.isCaution) {
            return 'utility:warning';
        }
        return 'utility:moneybag';
    }
    
    get bannerMessage() {
        if (this.isInactive) {
            return 'INACTIVE AGENCY';
        }
        
        const serviceText = this.numberOfUnpaidServices === 1 ? 'service' : 'services';
        
        if (this.isCritical) {
            return `CRITICAL: ${this.numberOfUnpaidServices} ${serviceText} outstanding`;
        }
        if (this.isWarning) {
            return `WARNING: ${this.numberOfUnpaidServices} ${serviceText} outstanding`;
        }
        if (this.isCaution) {
            return `ATTENTION: ${this.numberOfUnpaidServices} ${serviceText} outstanding`;
        }
        if (this.totalOutstandingBalance > 0) {
            return `BALANCE DUE (${this.numberOfUnpaidServices} ${serviceText})`;
        }
        return '';
    }
}