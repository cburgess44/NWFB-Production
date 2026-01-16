import { LightningElement, api, wire, track  } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getPickupsAndRequests from '@salesforce/apex/TruckSchedulerController.getPickupsAndRequests';
import createStop from '@salesforce/apex/TruckSchedulerController.createStop';

const DATATABLE_COLUMNS = [
    { label: 'TimeFrame', fieldName: 'timeFrame', wrapText: true },
    { label: 'Type', type: 'button', typeAttributes: { iconName: { fieldName: 'icon' }, label: { fieldName: 'title' }, name: 'type', title: 'editTitle', disabled: false, value: 'type', variant: 'base'}},
    { label: 'Contact', fieldName: 'contact' , type: 'url', wrapText: true, typeAttributes: { label: { fieldName: 'contactName' } },},
    { label: 'Destination', fieldName: 'description', wrapText: true },
    { label: 'Travel Time', fieldName: 'eta', wrapText: true },
    { label: 'Stop Time', fieldName: 'eta', wrapText: true },
    { label: 'Extra Time', fieldName: 'eta', wrapText: true },
    { label: 'Total Time', fieldName: 'eta', wrapText: true },
    { label: 'Items', fieldName: 'items', wrapText: true },
    {
        type: "button",
        fixedWidth: 80,
        typeAttributes: {
            label: 'view',
            title: 'view',
            name: 'view',
            value: 'view',
            variant: 'success',
            class: 'scaled-down'
        }
    },
    {
        type: "button",
        fixedWidth: 120,
        typeAttributes: {
            label: 'add to trip',
            title: 'add_to_trip',
            name: 'add_to_trip',
            value: 'add_to_trip',
            variant: 'destructive',
            class: 'scaled-down',
            disabled : {fieldName :'isAddable'},
        }
    },
]
const WEEKDAY = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
const MONTH = ["January","February","March","April","May","June","July","August","September","October","November","December"];

export default class TruckScheduler extends NavigationMixin(LightningElement)  {
    @api recordId;
    isLoaded = false;
    tripDate;
    error;
    locationName;
    @track mapMarkersFiltered = []
    @track mapMarkers = [];
    filterMarkers = []
    title;
    columns = DATATABLE_COLUMNS;

    //get record info to set title and location names
    @wire(getRecord, { recordId: '$recordId', fields: ['Trip__c.Location__r.Name', 'Trip__c.Date__c'] })
    record({ error, data }) {
        if (data) {
            this.error = undefined;
            //set location name
            this.locationName = getFieldValue(data, 'Trip__c.Location__r.Name');

            //set title date
            let date = new Date(getFieldValue(data, 'Trip__c.Date__c'));
            this.title = WEEKDAY[date.getDay()] + ', ' + MONTH[date.getMonth()] + ' ' + date.getDate() + 'th' 

            
            this.tripDate = getFieldValue(data, 'Trip__c.Date__c');
            this.getData(this.tripDate);
        } else if (error) {
            this.error = error;
            this.isLoaded = true;
        }
    }
    //get markers
    getData(tripDate){
        getPickupsAndRequests({ tripDate: tripDate }).then((data) => {
            this.error = undefined;
            this.mapMarkers = JSON.parse(JSON.stringify(data));
            this.mapMarkersFiltered = JSON.parse(JSON.stringify(data));
            this.isLoaded = true;
        }).catch((error) => {
            this.error = error;
            console.log(error);
            this.isLoaded = true;
        });
    }
    //handle checkbox click
    handleCheckboxClick(event) {
        let value = event.target.value;
        let element = this.mapMarkers.find(element => value == element.id);
        element.isChecked = !element.isChecked;
    }

    //handle filter click
    handleClickfilterMarkers(event){
        this.mapMarkersFiltered = this.mapMarkers.filter(element => {
            return element.isChecked
        });
    }

    //handle submit assign truck
    handleSubmit(event){
        this.isLoaded = false;
        event.preventDefault();       // stop the form from submitting
        const fields = event.detail.fields;
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    //handle success assign truck
    handleSuccess(event){
        const updatedRecord = event.detail.id;
        this.isLoaded = true;
        this.showToast('Success!', 'The assignment was made!', 'success');
    }
    //handle row dropdown action
    handleRowAction(event){
        const action = event.detail.action;
        const row = event.detail.row;

        switch (action.name) {
            case 'view':
                this.navigateToRecord(row.id);
                break;
            case 'add_to_trip':
                this.createStop(row);
                break;
        }
    }
    createStop(row){
        let items = JSON.parse(JSON.stringify(this.mapMarkers));
        items.forEach(element => {
            if(row.id == element.id){
                element.isAddable = true;
            }
        });
        this.mapMarkers = items;
        createStop({ stop: row, tripId: this.recordId }).then((data) => {
            this.showToast('Success!', 'Added successfully!', 'success');
        }).catch((error) => {
            let items = JSON.parse(JSON.stringify(this.mapMarkers));
            items.forEach(element => {
                if(row.id == element.id){
                    element.isAddable = false;
                }
            });
            this.mapMarkers = items;
            this.error = error;
            console.log(error);
            this.isLoaded = true;
        });
    }

    //show toast messages
    showToast(title, message, variant){
        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
        }));
    }
    navigateToRecord(recordId){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            },
        });
    }
    handleClickTripPage(event){
        this.navigateToTab('Trips')
    }
    navigateToTab(tabName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                //Name of any CustomTab. Visualforce tabs, web tabs, Lightning Pages, and Lightning Component tabs
                apiName: tabName
            },
        });
    }
}