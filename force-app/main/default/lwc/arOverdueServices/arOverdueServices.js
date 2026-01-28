import { LightningElement, wire, track } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOverdueServices from '@salesforce/apex/AR_OverdueServicesController.getOverdueServices';
import getEmailTemplates from '@salesforce/apex/AR_OverdueServicesController.getEmailTemplates';
import logCollectionCall from '@salesforce/apex/AR_OverdueServicesController.logCollectionCall';
import writeOffBalance from '@salesforce/apex/AR_OverdueServicesController.writeOffBalance';
import recordPayment from '@salesforce/apex/AR_OverdueServicesController.recordPayment';
import updateCollectionsStatus from '@salesforce/apex/AR_OverdueServicesController.updateCollectionsStatus';
import sendCollectionEmail from '@salesforce/apex/AR_OverdueServicesController.sendCollectionEmail';
import sendAgencySummaryEmail from '@salesforce/apex/AR_OverdueServicesController.sendAgencySummaryEmail';
import getAgencyAPContacts from '@salesforce/apex/AR_OverdueServicesController.getAgencyAPContacts';

const COLUMNS = [
    {
        label: '',
        fieldName: 'agingIcon',
        type: 'text',
        initialWidth: 50,
        cellAttributes: { 
            class: { fieldName: 'agingClass' },
            alignment: 'center'
        }
    },
    {
        label: 'Service',
        fieldName: 'recordUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'name' }, target: '_blank' },
        sortable: true
    },
    {
        label: 'Agency',
        fieldName: 'agencyUrl',
        type: 'url',
        typeAttributes: { label: { fieldName: 'agencyName' }, target: '_blank' },
        sortable: true
    },
    {
        label: 'Client',
        fieldName: 'contactName',
        type: 'text',
        sortable: true
    },
    {
        label: 'Balance Due',
        fieldName: 'balanceDue',
        type: 'currency',
        sortable: true,
        cellAttributes: { alignment: 'right' }
    },
    {
        label: 'Days',
        fieldName: 'daysOutstanding',
        type: 'number',
        sortable: true,
        initialWidth: 80,
        cellAttributes: { 
            alignment: 'right',
            class: { fieldName: 'agingClass' }
        }
    },
    {
        label: 'Aging Bucket',
        fieldName: 'agingBucket',
        type: 'text',
        sortable: true,
        cellAttributes: { 
            class: { fieldName: 'agingClass' }
        }
    },
    {
        label: 'Service Date',
        fieldName: 'serviceRenderedDate',
        type: 'date',
        sortable: true
    },
    {
        label: 'Invoice #',
        fieldName: 'invoiceNumber',
        type: 'text',
        sortable: true,
        initialWidth: 110
    },
    {
        label: 'Service Status',
        fieldName: 'status',
        type: 'text',
        sortable: true,
        initialWidth: 120
    },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Take Action', name: 'engage' },
                { label: 'View Record', name: 'view' }
            ]
        }
    }
];

// Field name mappings for URL columns (sort by display label, not URL)
const SORT_FIELD_MAP = {
    'recordUrl': 'name',
    'agencyUrl': 'agencyName'
};

// Sortable field options for dropdowns
const SORT_FIELD_OPTIONS = [
    { label: '-- None --', value: '' },
    { label: 'Service Name', value: 'name' },
    { label: 'Agency', value: 'agencyName' },
    { label: 'Client', value: 'contactName' },
    { label: 'Balance Due', value: 'balanceDue' },
    { label: 'Days Outstanding', value: 'daysOutstanding' },
    { label: 'Aging Bucket', value: 'agingBucket' },
    { label: 'Service Date', value: 'serviceRenderedDate' },
    { label: 'Invoice #', value: 'invoiceNumber' },
    { label: 'Service Status', value: 'status' }
];

const SORT_DIRECTION_OPTIONS = [
    { label: 'Ascending ↑', value: 'asc' },
    { label: 'Descending ↓', value: 'desc' }
];

const RECIPIENT_OPTIONS = [
    { label: 'Agency AP Contact', value: 'agency' },
    { label: 'Caseworker', value: 'caseworker' },
    { label: 'Client', value: 'client' }
];

const PAYMENT_METHOD_OPTIONS = [
    { label: 'Check', value: 'Check' },
    { label: 'Credit Card', value: 'Credit Card' },
    { label: 'Cash', value: 'Cash' },
    { label: 'ACH/Bank Transfer', value: 'ACH' },
    { label: 'Other', value: 'Other' }
];

const STATUS_OPTIONS = [
    { label: 'Not Started', value: 'Not Started' },
    { label: 'Contacted', value: 'Contacted' },
    { label: 'Payment Promised', value: 'Payment Promised' },
    { label: 'Payment Plan', value: 'Payment Plan' },
    { label: 'Disputed', value: 'Disputed' },
    { label: 'Unresponsive', value: 'Unresponsive' }
];

export default class ArOverdueServices extends LightningElement {
    @track services = [];
    @track originalServices = []; // Keep original for re-sorting
    @track error;
    @track isLoading = true;
    
    // Explicit sort controls
    @track primarySortField = 'daysOutstanding';
    @track primarySortDirection = 'desc';
    @track secondarySortField = '';
    @track secondarySortDirection = 'asc';
    
    // For datatable display (tracks primary sort)
    @track sortedBy = 'daysOutstanding';
    @track sortedDirection = 'desc';
    
    // Expose options to template
    sortFieldOptions = SORT_FIELD_OPTIONS;
    sortDirectionOptions = SORT_DIRECTION_OPTIONS;
    
    // Engagement Modal
    @track showEngagementModal = false;
    @track selectedService = {};
    
    // Email
    @track emailTemplates = [];
    @track selectedTemplateId = '';
    @track emailRecipientType = 'agency';
    
    // Payment
    @track paymentAmount = '';
    @track paymentMethod = 'Check';
    @track paymentNotes = '';
    
    // Write Off
    @track writeOffAmount = '';
    @track writeOffReason = '';
    
    // Log Call
    @track callNotes = '';
    @track callStatus = 'Contacted';
    
    // Agency Summary Modal
    @track showAgencySummaryModal = false;
    @track selectedAgencyId = '';
    @track agencySummaryPreview = {};
    @track isSendingAgencySummary = false;
    @track showEmailPreview = false; // Two-step confirmation
    @track agencyAPContacts = []; // AP Contacts for selected agency
    @track isLoadingAPContacts = false;
    
    columns = COLUMNS;
    recipientOptions = RECIPIENT_OPTIONS;
    paymentMethodOptions = PAYMENT_METHOD_OPTIONS;
    statusOptions = STATUS_OPTIONS;
    wiredServicesResult;

    @wire(getOverdueServices)
    wiredServices(result) {
        this.wiredServicesResult = result;
        
        if (result.data) {
            this.originalServices = result.data.map(svc => ({
                ...svc,
                formattedBalance: new Intl.NumberFormat('en-US', { 
                    style: 'currency', 
                    currency: 'USD' 
                }).format(svc.balanceDue)
            }));
            this.services = [...this.originalServices];
            this.applySorting(); // Apply current sort
            this.error = undefined;
            this.isLoading = false;
        } else if (result.error) {
            this.error = result.error.body?.message || 'Unknown error';
            this.services = [];
            this.isLoading = false;
        }
    }

    @wire(getEmailTemplates)
    wiredTemplates({ data, error }) {
        if (data) {
            this.emailTemplates = data;
        }
    }

    get templateOptions() {
        return this.emailTemplates.map(t => ({
            label: t.name,
            value: t.id
        }));
    }

    get hasServices() {
        return this.services && this.services.length > 0;
    }

    get totalServices() {
        return this.services ? this.services.length : 0;
    }

    get totalBalance() {
        if (!this.services) return 0;
        return this.services.reduce((sum, svc) => sum + (svc.balanceDue || 0), 0);
    }

    get formattedTotalBalance() {
        return new Intl.NumberFormat('en-US', { 
            style: 'currency', 
            currency: 'USD' 
        }).format(this.totalBalance);
    }

    get criticalCount() {
        if (!this.services) return 0;
        return this.services.filter(s => s.agingBucket === '90+ Days').length;
    }

    get warningCount() {
        if (!this.services) return 0;
        return this.services.filter(s => s.agingBucket === '61-90 Days').length;
    }

    get cautionCount() {
        if (!this.services) return 0;
        return this.services.filter(s => s.agingBucket === '31-60 Days').length;
    }

    get sendEmailDisabled() {
        return !this.selectedTemplateId;
    }

    get recordPaymentDisabled() {
        return !this.paymentAmount || this.paymentAmount <= 0;
    }

    get writeOffDisabled() {
        return !this.writeOffReason;
    }

    // Get unique agencies for the dropdown
    get agencyOptions() {
        if (!this.services) return [];
        const agencyMap = new Map();
        this.services.forEach(svc => {
            if (svc.agencyId && !agencyMap.has(svc.agencyId)) {
                agencyMap.set(svc.agencyId, svc.agencyName);
            }
        });
        return Array.from(agencyMap, ([value, label]) => ({ label, value }))
            .sort((a, b) => a.label.localeCompare(b.label));
    }

    // Get services for selected agency
    get selectedAgencyServices() {
        if (!this.selectedAgencyId || !this.services) return [];
        return this.services.filter(svc => svc.agencyId === this.selectedAgencyId);
    }

    get selectedAgencyTotal() {
        return this.selectedAgencyServices.reduce((sum, svc) => sum + (svc.balanceDue || 0), 0);
    }

    get formattedAgencyTotal() {
        return new Intl.NumberFormat('en-US', { 
            style: 'currency', 
            currency: 'USD' 
        }).format(this.selectedAgencyTotal);
    }

    get selectedAgencyName() {
        const agency = this.agencyOptions.find(a => a.value === this.selectedAgencyId);
        return agency ? agency.label : '';
    }

    get selectedAgencyPrimaryContactName() {
        if (!this.selectedAgencyId || !this.services) return '';
        const agencyService = this.services.find(svc => svc.agencyId === this.selectedAgencyId);
        return agencyService?.agencyPrimaryContactName || 'No Primary Contact';
    }

    get selectedAgencyPrimaryContactEmail() {
        if (!this.selectedAgencyId || !this.services) return '';
        const agencyService = this.services.find(svc => svc.agencyId === this.selectedAgencyId);
        return agencyService?.agencyPrimaryContactEmail || 'No Email on File';
    }

    get hasAgencyPrimaryContact() {
        if (!this.selectedAgencyId || !this.services) return false;
        const agencyService = this.services.find(svc => svc.agencyId === this.selectedAgencyId);
        return agencyService?.agencyPrimaryContactEmail ? true : false;
    }

    // Get unique caseworkers with emails for the selected agency
    get selectedAgencyCaseworkers() {
        if (!this.selectedAgencyId || !this.services) return [];
        const caseworkerMap = new Map();
        this.services
            .filter(svc => svc.agencyId === this.selectedAgencyId && svc.caseworkerId && svc.caseworkerEmail)
            .forEach(svc => {
                if (!caseworkerMap.has(svc.caseworkerId)) {
                    caseworkerMap.set(svc.caseworkerId, {
                        id: svc.caseworkerId,
                        name: svc.caseworkerName,
                        email: svc.caseworkerEmail
                    });
                }
            });
        return Array.from(caseworkerMap.values());
    }

    get hasAgencyCaseworkers() {
        return this.selectedAgencyCaseworkers.length > 0;
    }

    get hasAgencyAPContacts() {
        return this.agencyAPContacts && this.agencyAPContacts.length > 0;
    }

    get hasAnyRecipients() {
        return this.hasAgencyPrimaryContact || this.hasAgencyCaseworkers || this.hasAgencyAPContacts;
    }

    get totalRecipientCount() {
        let count = this.hasAgencyPrimaryContact ? 1 : 0;
        count += this.selectedAgencyCaseworkers.length;
        count += this.agencyAPContacts ? this.agencyAPContacts.length : 0;
        return count;
    }

    get sendAgencySummaryDisabled() {
        return !this.selectedAgencyId || this.selectedAgencyServices.length === 0;
    }

    // Get secondary sort options (exclude primary field)
    get secondarySortFieldOptions() {
        return SORT_FIELD_OPTIONS.filter(opt => 
            opt.value === '' || opt.value !== this.primarySortField
        );
    }

    // For disabling controls in template
    get isPrimarySortEmpty() {
        return !this.primarySortField;
    }

    get isSecondarySortEmpty() {
        return !this.secondarySortField;
    }

    handleRefresh() {
        this.isLoading = true;
        refreshApex(this.wiredServicesResult)
            .then(() => {
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                this.showToast('Error', 'Failed to refresh data', 'error');
            });
    }

    // Sort control handlers
    handlePrimarySortFieldChange(event) {
        this.primarySortField = event.detail.value;
        // If primary is cleared, clear secondary too
        if (!this.primarySortField) {
            this.secondarySortField = '';
        }
        // If secondary is same as new primary, clear it
        if (this.secondarySortField === this.primarySortField) {
            this.secondarySortField = '';
        }
        this.applySorting();
    }

    handlePrimarySortDirectionChange(event) {
        this.primarySortDirection = event.detail.value;
        this.applySorting();
    }

    handleSecondarySortFieldChange(event) {
        this.secondarySortField = event.detail.value;
        this.applySorting();
    }

    handleSecondarySortDirectionChange(event) {
        this.secondarySortDirection = event.detail.value;
        this.applySorting();
    }

    // Datatable header click - just set as primary sort
    handleSort(event) {
        const fieldName = event.detail.fieldName;
        const sortDirection = event.detail.sortDirection;
        
        // Map URL fields to their display counterparts
        const actualField = SORT_FIELD_MAP[fieldName] || fieldName;
        
        this.primarySortField = actualField;
        this.primarySortDirection = sortDirection;
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        
        this.applySorting();
    }

    // Reset to default sort
    handleClearSort() {
        this.primarySortField = 'daysOutstanding';
        this.primarySortDirection = 'desc';
        this.secondarySortField = '';
        this.secondarySortDirection = 'asc';
        this.sortedBy = 'daysOutstanding';
        this.sortedDirection = 'desc';
        this.applySorting();
    }

    applySorting() {
        if (!this.originalServices || this.originalServices.length === 0) return;
        
        const parseData = JSON.parse(JSON.stringify(this.originalServices));
        
        // Build sort columns array
        const sortColumns = [];
        if (this.primarySortField) {
            sortColumns.push({ field: this.primarySortField, direction: this.primarySortDirection });
        }
        if (this.secondarySortField) {
            sortColumns.push({ field: this.secondarySortField, direction: this.secondarySortDirection });
        }
        
        if (sortColumns.length === 0) {
            this.services = parseData;
            return;
        }
        
        parseData.sort((a, b) => {
            for (const sortCol of sortColumns) {
                const field = sortCol.field;
                const isReverse = sortCol.direction === 'asc' ? 1 : -1;
                
                let valueA = a[field];
                let valueB = b[field];
                
                // Handle nulls
                if (valueA == null && valueB == null) continue;
                if (valueA == null) return 1;
                if (valueB == null) return -1;
                
                // Handle strings
                if (typeof valueA === 'string') {
                    valueA = valueA.toLowerCase();
                    valueB = (valueB || '').toLowerCase();
                }
                
                if (valueA < valueB) return -1 * isReverse;
                if (valueA > valueB) return 1 * isReverse;
            }
            return 0;
        });
        
        this.services = parseData;
        
        // Update datatable indicators
        this.sortedBy = this.primarySortField;
        this.sortedDirection = this.primarySortDirection;
    }

    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        
        switch (action.name) {
            case 'view':
                window.open(row.recordUrl, '_blank');
                break;
            case 'engage':
                this.openEngagementModal(row);
                break;
            default:
                break;
        }
    }

    openEngagementModal(service) {
        this.selectedService = service;
        this.resetModalFields();
        this.showEngagementModal = true;
    }

    closeEngagementModal() {
        this.showEngagementModal = false;
        this.selectedService = {};
        this.resetModalFields();
    }

    resetModalFields() {
        this.selectedTemplateId = '';
        this.emailRecipientType = 'agency';
        this.paymentAmount = '';
        this.paymentMethod = 'Check';
        this.paymentNotes = '';
        this.writeOffAmount = '';
        this.writeOffReason = '';
        this.callNotes = '';
        this.callStatus = 'Contacted';
    }

    handleViewRecord() {
        window.open(this.selectedService.recordUrl, '_blank');
    }

    // Email handlers
    handleRecipientChange(event) {
        this.emailRecipientType = event.detail.value;
    }

    handleTemplateChange(event) {
        this.selectedTemplateId = event.detail.value;
    }

    handleSendEmail() {
        sendCollectionEmail({ 
            serviceId: this.selectedService.id, 
            templateId: this.selectedTemplateId,
            recipientType: this.emailRecipientType
        })
        .then(() => {
            this.showToast('Success', 'Email sent successfully', 'success');
            this.closeEngagementModal();
            this.handleRefresh();
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || 'Error sending email', 'error');
        });
    }

    // Payment handlers
    handlePaymentAmountChange(event) {
        this.paymentAmount = event.detail.value;
    }

    handlePaymentMethodChange(event) {
        this.paymentMethod = event.detail.value;
    }

    handlePaymentNotesChange(event) {
        this.paymentNotes = event.detail.value;
    }

    handleRecordPayment() {
        recordPayment({ 
            serviceId: this.selectedService.id, 
            amount: parseFloat(this.paymentAmount),
            paymentMethod: this.paymentMethod,
            notes: this.paymentNotes
        })
        .then(() => {
            this.showToast('Success', 'Payment recorded successfully', 'success');
            this.closeEngagementModal();
            this.handleRefresh();
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || 'Error recording payment', 'error');
        });
    }

    // Write Off handlers
    handleWriteOffAmountChange(event) {
        this.writeOffAmount = event.detail.value;
    }

    handleWriteOffReasonChange(event) {
        this.writeOffReason = event.detail.value;
    }

    handleWriteOff() {
        writeOffBalance({ 
            serviceId: this.selectedService.id, 
            reason: this.writeOffReason,
            amount: this.writeOffAmount ? parseFloat(this.writeOffAmount) : null
        })
        .then(() => {
            this.showToast('Success', 'Balance written off successfully', 'success');
            this.closeEngagementModal();
            this.handleRefresh();
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || 'Error writing off balance', 'error');
        });
    }

    // Log Call handlers
    handleCallNotesChange(event) {
        this.callNotes = event.detail.value;
    }

    handleCallStatusChange(event) {
        this.callStatus = event.detail.value;
    }

    handleLogCall() {
        updateCollectionsStatus({ 
            serviceId: this.selectedService.id, 
            status: this.callStatus,
            notes: this.callNotes
        })
        .then(() => {
            this.showToast('Success', 'Call logged successfully', 'success');
            this.closeEngagementModal();
            this.handleRefresh();
        })
        .catch(error => {
            this.showToast('Error', error.body?.message || 'Error logging call', 'error');
        });
    }

    // =========================================================================
    // AGENCY SUMMARY EMAIL
    // =========================================================================
    
    openAgencySummaryModal() {
        this.selectedAgencyId = '';
        this.showEmailPreview = false;
        this.showAgencySummaryModal = true;
    }

    closeAgencySummaryModal() {
        this.showAgencySummaryModal = false;
        this.selectedAgencyId = '';
        this.showEmailPreview = false;
        this.agencyAPContacts = [];
    }

    handleAgencyChange(event) {
        this.selectedAgencyId = event.detail.value;
        this.showEmailPreview = false; // Reset preview when agency changes
        this.agencyAPContacts = [];
        
        // Fetch AP Contacts for this agency
        if (this.selectedAgencyId) {
            this.isLoadingAPContacts = true;
            getAgencyAPContacts({ agencyId: this.selectedAgencyId })
                .then(result => {
                    this.agencyAPContacts = result;
                })
                .catch(error => {
                    console.error('Error fetching AP contacts:', error);
                    this.agencyAPContacts = [];
                })
                .finally(() => {
                    this.isLoadingAPContacts = false;
                });
        }
    }

    // Step 1: Show email preview for proofing
    handlePreviewEmail() {
        if (!this.selectedAgencyId) return;
        this.showEmailPreview = true;
    }

    // Go back to edit/select different agency
    handleBackToSelect() {
        this.showEmailPreview = false;
    }

    // Step 2: Actually send after confirmation
    handleConfirmAndSend() {
        if (!this.selectedAgencyId) return;
        
        this.isSendingAgencySummary = true;
        
        sendAgencySummaryEmail({ agencyId: this.selectedAgencyId })
            .then(() => {
                this.showToast('Success', 
                    `Summary email sent to ${this.selectedAgencyName} for ${this.selectedAgencyServices.length} services totaling ${this.formattedAgencyTotal}`, 
                    'success');
                this.closeAgencySummaryModal();
                this.handleRefresh();
            })
            .catch(error => {
                this.showToast('Error', error.body?.message || 'Error sending agency summary', 'error');
            })
            .finally(() => {
                this.isSendingAgencySummary = false;
            });
    }

    get previewEmailDisabled() {
        return !this.selectedAgencyId || this.selectedAgencyServices.length === 0 || !this.hasAnyRecipients;
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}
