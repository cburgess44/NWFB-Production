import {LightningElement, wire, api, track} from 'lwc';
import fetchRecords from '@salesforce/apex/RelatedListController.fetchRecords';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';
import getRecordTypeIdsByObject from '@salesforce/apex/CustomRequestItemsRelatedListController.getRecordTypeIdsByObject';

import {getRecord, getFieldValue, updateRecord} from "lightning/uiRecordApi";
import {getObjectInfo} from "lightning/uiObjectInfoApi";

import SERVICE_STATUS_API_NAME from "@salesforce/schema/Service__c.Status__c";
import SERVICE_SUBTYPE from "@salesforce/schema/Service__c.SubType__c";
import SERVICE_ID_API_NAME from "@salesforce/schema/Service__c.Id";
import SERVICE_RECORDTYPE_NAME from "@salesforce/schema/Service__c.RecordType.Name";
import SERVICE_RECORDTYPE_ID from "@salesforce/schema/Service__c.RecordTypeId";
import SERVICE_SHOPPING_APPOINTMENT from "@salesforce/schema/Service__c.ShoppingAppointmentComplete__c";
import SERVICE_INVOICE_CREATED from "@salesforce/schema/Service__c.InvoiceCreated__c";
import SERVICE_TOTAL_PAID from "@salesforce/schema/Service__c.TotalPaid__c";
import SERVICE_TOTAL_ITEMS from "@salesforce/schema/Service__c.Total_Items__c";
import SERVICE_TOTAL_COMPLETEDITEMS from "@salesforce/schema/Service__c.ItemsCompleted__c";
import USER_PROFILE from "@salesforce/schema/User.Profile.Name";

import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';

import userId from '@salesforce/user/Id';
import {refreshApex} from '@salesforce/apex';

export default class CustomRequestItemsRelatedList extends NavigationMixin(LightningElement) {

    @api
    recordId;

    @api
    objectName;

    @api
    refField;

    @api
    parentFieldAPIName;

    @api
    parentObjectName;

    @api
    parentFieldName;

    @api
    relationshipApiName;

    @api
    newRecordAvailable;

    @api
    tableData = [];

    @api
    field1;

    @api
    field2;

    @api
    field3;

    @api
    field4;

    @api
    field5;

    @api
    field6;

    @api
    showFlexibleProducts;

    @api
    showStaffRequestableItems;

    @track
    fileUploadRecordId;

    @track
    openFileUpload = false;

    @track
    currentServiceItemPhotoUrl;

    @track
    enableServiceItemPhotoModal = false;

    @track
    fieldValue;

    @track
    lstSelectedRecords = [];

    @track
    columns = [];

    @track
    status;

    @track
    notesLabel;

    @track
    notesValue;

    @track
    isShowNotesModal = false;

    @track
    completeAppointment = false;

    @track
    selectedStatus = '';

    @track
    isShowModal = false;

    @track
    titleWithCount;

    @track
    inputVariables;

    @track
    countBool = false;

    @track
    showAppointmentComplete = false;

    @track
    showNew = false;

    @track
    showFlexibleItems = false;

    @track
    serviceRecordType = false;

    @track
    enableProvidedCollumn = true;

    @track
    enableRequestedCollumn = false;

    @track
    enableDeliveryQuantityButton = false;

    @track
    userProfile;

    @track
    loading = false;

    recordTypeIds = {};
    fetchData;
    saveListener;
    recordType;
    recordTypeId;
    shoppingAppointment; 
    completedItems;
    msgCompleteAppointment;
    selectedItems;
    domainSite;
    rowNotes;

    //User profile Wire
    @wire(getRecord, {recordId: userId, fields: [USER_PROFILE]})
    currentUserInfo(value) {
        if (value.data) {
            this.userProfile = value.data.fields.Profile.displayValue;

            if(this.userProfile === 'NWFB Platform Volunteer'){
                this.showNew = false;
                this.showAppointmentComplete = false;
            } else {
                this.showNew = true;
            }
        }
    }

    ItemsCompleted
    //Service Wire
    @wire(getRecord, {
        recordId: "$recordId",
        fields: [
            SERVICE_STATUS_API_NAME,
            SERVICE_SUBTYPE,
            SERVICE_INVOICE_CREATED,
            SERVICE_SHOPPING_APPOINTMENT,
            SERVICE_TOTAL_COMPLETEDITEMS,
            SERVICE_ID_API_NAME,
            SERVICE_RECORDTYPE_NAME,
            SERVICE_TOTAL_PAID,
            SERVICE_TOTAL_ITEMS,
            SERVICE_RECORDTYPE_ID
        ],
        optionalFields: "$parentFieldName"
    })

    customObject(value) {
        if (value.data) {
            this.fieldValue = getFieldValue(value.data, this.refField)?.substring(0, 15);
            this.parentObjectNameId = getFieldValue(value.data, this.parentFieldName);
            this.status = getFieldValue(value.data, SERVICE_STATUS_API_NAME);
            this.recordType = value.data?.recordTypeInfo?.name;
            this.recordTypeId = value.data?.recordTypeInfo?.recordTypeId;
            this.shoppingAppointment = getFieldValue(value.data, SERVICE_SHOPPING_APPOINTMENT);
            this.showFlexibleItems = ((this.status === 'Shopping' && this.recordType === 'Client Request') ||
                ((this.status === 'Processing' || this.status === 'Routing') && this.recordType === 'Donation Pickup'));
        }
        console.log('showNew => ' + this.showNew);
        console.log('recordType => ' + this.recordType === 'Client Request');
        console.log('shoppingAppointment => ' + this.shoppingAppointment);
        console.log('status => ' + this.status);

        this.showAppointmentComplete = (
            this.showNew
            && this.recordType === 'Client Request'
            && this.shoppingAppointment == null
            && this.status === 'Shopping'
        );


        if (getFieldValue(value.data, SERVICE_SUBTYPE) === 'Will Call') {
            if (getFieldValue(value.data, SERVICE_TOTAL_ITEMS) === getFieldValue(value.data, SERVICE_TOTAL_COMPLETEDITEMS)) {
                this.completedItems = true;
            } else {
                this.completedItems = false;
                this.msgCompleteAppointment = 'For the Will Call subtype, all provided items must have a status of Completed';
            }
        } else {
            if (getFieldValue(value.data, SERVICE_INVOICE_CREATED) != null || getFieldValue(value.data, SERVICE_TOTAL_PAID) > 0) {
                this.completedItems = true;
            } else {
                this.completedItems = false;
                this.msgCompleteAppointment = 'It is necessary to have an invoice created or payment made in order to complete an appointment';
            }
        }
    }

    get options() {
        return [
            {label: 'Requested', value: 'Requested'},
            {label: 'Staged', value: 'Staged'},
            {label: 'Loaded ', value: 'Loaded '},
            {label: 'Not Loaded', value: 'Not Loaded'},
            {label: 'Completed', value: 'Completed'},
            {label: 'Not Available', value: 'Not Available'},
            {label: 'Shopping Declined', value: 'Shopping Declined'},
        ];
    }

    handleChange(event) {
        this.selectedStatus = event.detail.value;
    }

    async saveNewStatus() {
        if (this.selectedStatus === '') {
            this.showToast('Select one value', 'Please select one value', 'warning');
        } else {
            this.lstSelectedRecords.forEach(row => {
                row.Status__c = this.selectedStatus;
                row.selected = false;
                // this.updateRow(row);
            });
            await this.updateRows(this.lstSelectedRecords);
            this.hideShowModal();
        }
    }

    @wire(fetchRecords, {listValues: '$vals'})
    accountData(value) {
        this.fetchData = value;

        const data = value.data;
        const error = value.error;

        if (data) {
            this.tableData = [];
            this.fetchTableData(data?.listRecords);

            if (data.recordCount != null) {
                if (data.recordCount > 3) {
                    this.titleWithCount = this.objectInfo.data?.labelPlural + ' (3+)';
                    this.countBool = true;
                } else {
                    this.countBool = false;
                    this.titleWithCount = this.objectInfo.data?.labelPlural + ' (' + data.recordCount + ')';
                }

                if (typeof this.titleWithCount === 'undefined') {
                    this.titleWithCount = 'Service Items ' + '(' + data.recordCount + ')';
                }
            }
        } else if (error) {
            console.error('Error: ', error);
        }
    }


    @wire(getObjectInfo, {objectApiName: "$objectName"})
    objectInfo;

    get vals() {
        return this.fieldValue
            + '-'
            + this.objectName
            + '-'
            + this.parentFieldAPIName
            + '-'
            + this.field1
            + ','
            + this.field2
            + ','
            + this.field3
            + ','
            + this.field4
            + ','
            + 'Status__c,'
            + 'Total_Fee__c,'
            + 'ItemPhotoURL__c,'
            + 'Total_Estimated_Value__c,'
            + `Service__r.RecordType.Name, 
               Service__r.RecordType.DeveloperName, 
               Service__r.RecordTypeId, 
               Service__r.SubType__c, 
               Service__r.Status__c, 
               ItemNotes__c`;
    }

    objectUrl() {
        // Navigate to list view
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                "objectApiName": this.objectName,
                "actionName": "list"
            },
        });
    }

    get iconName() {
        if (!this.objectInfo.data || !this.objectInfo.data.themeInfo.iconUrl) {
            return ('standard:custom')
        }

        let url = this.objectInfo.data ? this.objectInfo.data.themeInfo.iconUrl : '';
        let name = url.substring(url.lastIndexOf("/"), url.length);
        url = url.substring(0, url.lastIndexOf("/"));
        let type = url.substring(url.lastIndexOf("/"), url.length);
        let icName = this.replaceAt(url.lastIndexOf("/"), ":", type + name).replace("/", "");
        icName = icName.substring(0, icName.length - 9).replace("/", ":");
        return icName;
    }

    @wire(getRecordTypeIdsByObject, { objectApiName: 'ServiceItem__c' })
    wiredRecordTypes({ error, data }) {
        if (data) {
            this.recordTypeIds = data;
        } else if (error) {
            console.error('Error fetching record type ids: ', error);
        }
    }

    replaceAt(index, replacement, str) {
        return (
            str.substr(0, index) +
            replacement +
            str.substr(index + replacement.length)
        );
    }

    connectedCallback() {
        window.addEventListener("unload", (e) => {});

        this.selectedItems = [];

        this.inputVariables = [{
            name: 'recordId',
            type: 'String',
            value: this.recordId
        }];
    }

    async handleAddNewProduct(event) {
        try {
            this.loading = true;
            // const existingItem = this.tableData.find(item => item.Product__c === event.detail);
            //
            // if (existingItem) {
            //     existingItem.Quantity__c += 1;
            //     await saveSObjects({sObjects: [existingItem]});
            // } else {

            const newServiceItem = {
                sobjectType: 'ServiceItem__c',
                Service__c: this.recordId,
                Product__c: event.detail,
                Quantity__c: 1,
                Quantity_Requested__c: 0,
                Status__c: 'Requested',
            }

            await saveSObjects({sObjects: [newServiceItem]});
            // }

            this.showToast('Success!', 'The service item was added successfully', 'success');
            await refreshApex(this.fetchData);
            this.loading = false;
        } catch (e)  {
           console.error('error adding new product ' + JSON.stringify(e));
        }
    }


    createNew(row) {
        const recordTypeId = this.recordType.includes('Client Request')
            ? this.recordTypeIds['Client Request Item']
            : this.recordTypeIds['Pickup and Delivery'];

        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: this.objectName,
                actionName: 'new'
            },
            state: {
                count: '1',
                nooverride: '1',
                useRecordTypeCheck: '1',
                recordTypeId: recordTypeId,
                defaultFieldValues: 'Service__c=' + this.recordId,
                navigationLocation: 'RELATED_LIST'
            }
        });

        this.saveListener = setInterval(async () => {
            if (location.pathname !== '/lightning/o/ServiceItem__c/new') {
                await refreshApex(this.fetchData);
                clearInterval(this.saveListener);

                if (this.showFlexibleItems) {
                    await this.template.querySelector('c-flexible-items').updateItems();
                }
            }
        }, 500);

    }
    navigateToRelatedList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.parentObjectNameId,
                objectApiName: this.parentObjectName,
                relationshipApiName: this.relationshipApiName,
                actionName: 'view'
            }
        });

        this.saveListener = setInterval(async () => {
            if (location.pathname !== '/lightning/o/ServiceItem__c/new') {
                await refreshApex(this.fetchData);
                clearInterval(this.saveListener);
            }
        }, 500);
    }

    handleSelectItem(event) {
        const itemId = event.target.dataset.id;
        const item = this.tableData.find((item) => item.Id === itemId);

        if (event.target.checked) {
            this.selectedItems.push(item);
        } else {
           this.selectedItems = this.selectedItems.filter((selectedItem) => selectedItem.Id !== itemId);
        }
    }

    handleMouseOver(event) {
        const tooltip = event.currentTarget.querySelector('.note-tooltip');
        tooltip.classList.remove('slds-hide');
    }

    handleMouseOut(event) {
        const tooltip = event.currentTarget.querySelector('.note-tooltip');
        tooltip.classList.add('slds-hide');
    }

    handleChangeQuantity(event) {
        const actionName = event.target.dataset.name;
        const rowId = event.target.dataset.id;
        const row = this.tableData.find((item) => item.Id === rowId);
        const shouldChangeDeliveredQuantity = row.Status__c === 'Loaded' && this.status === 'Delivery'
            && this.recordType === 'General Delivery';

        if (actionName === 'add' && shouldChangeDeliveredQuantity) {
            row.Quantity_Requested__c += 1;
            this.updateRow(row);
            return;
        }

        if (actionName === 'subtract' && row['Quantity__c'] !== 0 && shouldChangeDeliveredQuantity) {
            row.Quantity_Requested__c -= 1;
            this.updateRow(row);
            return;
        }

        if (actionName === 'add') {
           row.Quantity__c += 1;
            this.updateRow(row);
            return;
        }

        if (actionName === 'subtract' && row['Quantity__c'] !== 0) {
            row.Quantity__c -= 1;
            this.updateRow(row);
        }
    }

    handleUploadFile(event) {
        const rowId = event.target.dataset.id;
        this.fileUploadRecordId = rowId;
        this.openFileUpload = rowId;
    }

    handleChangeStatus(event) {
        const status = event.target.dataset.status;
        const rowId = event.target.dataset.id;
        const row = this.tableData.find((item) => item.Id === rowId);
        const shouldChangeDeliveredQuantity = this.status === 'Delivery' && this.recordType === 'General Delivery';

        if (status === 'Item Rejected') {
             row['Status__c'] = status;
             this.updateRow(row);
        } else if (status === 'Not Delivered') {
            this.rowNotes = row;
            this.notesLabel = 'Not Delivered Item Notes';
            row['Status__c'] = status;
            this.hideShowNotesModal();
        } else if (status === 'Completed') {
            if(row['Quantity_Requested__c'] === 0 || shouldChangeDeliveredQuantity) {
                row['Quantity_Requested__c'] = row['Quantity__c'];
            }
            row['Status__c'] = status;
            this.updateRow(row);
        } else if (status === 'Loaded') {
            if (row['Quantity__c'] === 0) {
                this.showToast(
                    'Warning!',
                    'This status requires at least one provided item on this line.',
                    'warning'
                );
            } else {
                row['Status__c'] = 'Loaded';
                this.updateRow(row);
            }
        } else if (status === 'Not Available') {
            row['Quantity__c'] = 0;
            row['Status__c'] = 'Not Available';
            this.updateRow(row);
        } else if (status === 'Staged') {
            row['Status__c'] = 'Staged';
            this.updateRow(row);
        } else if (status === 'Declined') {
            if (row['Status__c'] === 'Shopping Declined') {
                row['Status__c'] = 'Requested';
            } else {
                row['Status__c'] = 'Shopping Declined';
                row['Quantity__c'] = 0;
            }
            this.updateRow(row);
        } else if (status === 'Not Loaded') {
            if (row['Quantity__c'] === 0) {
                this.showToast('Warning!', 'This status requires at least one provided item on this line.', 'warning');
            } else {
                row['Status__c'] = 'Not Loaded';
                this.rowNotes = row;
                this.notesLabel = 'Not Loaded Item Notes';
                this.hideShowNotesModal();
            }
        }
    }

    add(element, number) {
        element.Quantity__c += number;
    }

    get acceptedFormats() {
        return ['.pdf', '.png', '.jpg', '.jpeg'];
    }

    async handleUploadFinished(event) {
        this.openFileUpload = false;

        const uploadedFile = event.detail.files[0];
        const serviceItem = this.tableData.find((td) => td.Id === this.fileUploadRecordId);

        serviceItem.ItemPhotoURL__c = window.location.origin
        + `/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Jpg&versionId=${uploadedFile.contentVersionId}`
        + `&operationContext=CHATTER&contentId=${uploadedFile.contentBodyId}`;

        await this.updateRows([serviceItem]);

        this.showToast(
            'Success!',
            'Photo uploaded successfully!',
            'success'
        );
    }

    closeModal() {
        this.openFileUpload = false;
    }

    updateRow(row) {
        let fields = {
            Id: row.Id,
            Status__c: row.Status__c,
            Quantity_Requested__c: row.Quantity_Requested__c,
            ItemNotes__c: row.ItemNotes__c,
            Quantity__c: row.Quantity__c
        }

        const recordInput = {fields};

        updateRecord(recordInput).then(async () => {
            this.showToast('Success!', 'The request item was updated', 'success');
            await refreshApex(this.fetchData);
        }).catch((error) => {
            console.error(error);
        });
    }

    async updateRows(rows) {
        await saveSObjects({sObjects: rows});       
        this.showToast('Success!', 'The request item was updated', 'success'); 
        await refreshApex(this.fetchData);
    }

    //show toast method
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
            Title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
        }));
    }

    async getSelectedRec() {
        if (this.selectedItems.length > 0) {
            this.lstSelectedRecords = [...this.selectedItems];
            this.hideShowModal();
        } else {
            this.showToast('No Service Item selected.', 'Please select at least one service item to change status.', 'warning');
        }
    }

    hideShowModal() {
        this.isShowModal = !this.isShowModal;
    }

    hideShowNotesModal() {
        this.isShowNotesModal = !this.isShowNotesModal;
    }

    handleAppointmentFlow() {
        if (this.completedItems) {
            this.completeAppointment = !this.completeAppointment;
        } else {
            this.showToast('Warning', this.msgCompleteAppointment, 'warning');
        }
    }

    handleFlow(event) {
        if (event.detail.status === 'FINISHED') {
            this.handleAppointmentFlow();
            window.location.reload()
        }
    }

    fetchTableData(listRecords) {
        this.tableData = [];

        listRecords.forEach((element) => {
            let obj = JSON.parse(JSON.stringify(element));

            obj['recordUrl'] = '/' + element.Id;
            obj['Name'] = element.Product__r?.Name;

            obj.loadedButtonName = 'Loaded';
            obj.itemRejectedButtonName = 'Item Rejected';
            obj.notLoadedButtonName = 'Not Loaded';
            obj.notDeliveredButtonName = 'Not Delivered';
            obj.declinedButtonName = 'Declined';
            obj.stagedButtonName = 'Staged';
            obj.notAvailableButtonName = 'Not Available';
            obj.completedButtonName = 'Completed';

            obj.enableDeclinedButton = false;
            obj.enableNotAvailableButton = false;
            obj.enableStagedButton = false;
            obj.enableNotLoadedButton = false;
            obj.enableLoadedButton = false;
            obj.enableNotDeliveredButton = false;
            obj.enableCompletedButton = false;
            obj.enableItemRejectedButton = false;
            obj.enableDeliveryQuantitiesButton = false;
            obj.enableItemNotes = false;
            obj.enableProvidedQuantitiesButton = false;
            obj.enableRequestedCollumn = false;
            this.enableRequestedCollumn = false;

            obj.field2 = obj[this.field2];
            obj.field3 = obj[this.field3];
            obj.field4 = obj[this.field4];
            obj.field5 = obj[this.field5];
            // obj.totalPrice = obj['Total_Estimated_Value__c'];
            obj.totalPrice = obj['Total_Fee__c'];

            // We always show the provided column (this is the main quantities)
            obj.enableProvidedCollumn = true;
            this.enableProvidedCollumn = true;

            // Set quantities to 0 if nothing set yet.
            if (!obj.Quantity__c) {
                obj.Quantity__c = 0;
            }

            if (!obj.Quantity_Requested__c) {
                obj.Quantity_Requested__c = 0;
            }

            // Show notes if they exist
            if (obj.ItemNotes__c !== undefined && obj.ItemNotes__c.length > 0) {
                obj.enableItemNotes = true;
            }

            // A. Client service process
            if (obj.Service__r.RecordType.Name === 'Client Request') {
                
                // Old code that was set for client requests, not sure why we have this...
                this.serviceRecordType = true;

                // For client requests we want to show the requested column
                obj.enableRequestedCollumn = true;
                this.enableRequestedCollumn = true;

                // Step 1. Shopping appointment
                if (obj.Service__r.Status__c === 'Shopping' && obj.Status__c === 'Requested') {
                    obj.enableDeclinedButton = true;
                    obj.enableNotAvailableButton = true;
                    obj.enableProvidedQuantityButton = true;
                }

                // Step 2a. Will call - Load items onto client's vehicle(s) and mark items as completed
                if (obj.Status__c === 'Requested' && obj.Service__r.SubType__c === 'Will Call' && obj.Quantity__c > 0){
                    obj.enableCompletedButton = true;
                }

                // Step 2b. Move items to staging if not will call
                if (obj.Status__c === 'Requested' && obj.Service__r.SubType__c !== 'Will Call' && obj.Quantity__c > 0) {
                    obj.enableStagedButton = true;
                }

                // Step 3. Loading the trucks for items in staging
                if (obj.Service__r.Status__c === 'Delivery' && obj.Status__c === 'Staged' && obj.Quantity__c > 0 ) {
                    obj.enableLoadedButton = true;
                    obj.enableNotLoadedButton = true;
                }

                // Step 4. Finish the delivery
                if (obj.Service__r.Status__c === 'Delivery' && obj.Status__c === 'Loaded') {
                    obj.enableNotDeliveredButton = true;
                    obj.enableItemRejectedButton = true;
                    obj.enableCompletedButton = true;
                }

            }
             
            // B. Other Record Types
            if (obj.Service__r.RecordType.Name !== 'Client Request') {
                
                //Step 1. Manually add items and change quantities
                if (obj.Service__r.Status__c === 'Processing'|| obj.Service__r.Status__c === 'Routing') {
                    obj.enableProvidedQuantityButton = true;
                }

                // Step 2a. Delivery
                if (obj.Service__r.Status__c === 'Delivery') {
                    if (obj.Status__c === 'Requested'){
                        obj.enableLoadedButton = true;
                        obj.enableNotLoadedButton = true;
                    } else if (obj.Status__c === 'Loaded'){
                        obj.enableItemRejectedButton = true;
                        obj.enableCompletedButton = true;
                        obj.enableNotDeliveredButton = true;
                    } 
                }

                // Step 2b. General Pickup or Donation Pickup
                if (obj.Service__r.Status__c === 'Pick Up' && obj.Status__c === 'Requested'){
                    obj.enableItemRejectedButton = true;
                    obj.enableCompletedButton = true;
                }
            }

            this.tableData.push(obj);
        });

        this.tableData.sort((a, b) =>
            a.Product__r.Name.toLowerCase().localeCompare(b.Product__r.Name.toLowerCase())
        );
    }

    saveNewStatusAndNotes() {
        const notes = this.template.querySelector('lightning-textarea').value;
        if (notes !== '' && notes !== null) {
            this.rowNotes.ItemNotes__c = notes;
            this.updateRow(this.rowNotes);
            this.notesLabel = '';
            this.rowNotes = null;
            this.hideShowNotesModal();
        } else {
            this.showToast('Item Notes', 'Please fill in the item notes', 'warning');
        }
    }

    handleViewPhoto(event) {
        const itemId = event.target.dataset.id;
        const serviceItem = this.tableData.find((td) => td.Id === itemId);
        this.currentServiceItemPhotoUrl = serviceItem.ItemPhotoURL__c;

        this.enableServiceItemPhotoModal = true;
    }

    handleCloseServiceItemPhotoModal(event) {
        this.enableServiceItemPhotoModal = false;
        this.currentServiceItemPhotoUrl = null;
    }
}