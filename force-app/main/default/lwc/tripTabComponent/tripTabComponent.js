import { LightningElement, wire, track  } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import userId from '@salesforce/user/Id';
import { getRecord,getFieldValue,updateRecord } from 'lightning/uiRecordApi';
import getLocations from '@salesforce/apex/TripTabComponentController.getLocations';
const COLUMNS_PENDING = [
    { label: 'Date', fieldName: 'tripDate', type: 'date-local',typeAttributes:{
        weekday: "long",
        month: "short",
        day: "2-digit"
    }, hideDefaultActions: true, fixedWidth: 160, cellAttributes: { alignment: 'left' } },
    {
        type: "button",
        initialWidth: 150,
        typeAttributes: {
            label: 'Assign Truck',
            title: 'Assign Truck',
            name: 'viewDetails',
            value: 'viewDetails',
            variant: 'success',
            class: 'scaled-down'
        }
    },
    { label: 'Destination', fieldName: 'destination', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }  },
    { label: 'Pickups', fieldName: 'pickups', type: 'number', initialWidth: 130, hideDefaultActions: true, cellAttributes: { alignment: 'center' }  },
    { label: 'Deliveries', fieldName: 'deliveries', type: 'number', initialWidth: 130, hideDefaultActions: true, cellAttributes: { alignment: 'center' }  },
];
const COLUMNS = [
    { label: 'Date', fieldName: 'tripDate', type: 'date-local',typeAttributes:{
        month: "2-digit",
        day: "2-digit",
        year: "2-digit",
    }, hideDefaultActions: true, fixedWidth: 160, cellAttributes: { alignment: 'left' } },
    { label: 'Timeframe(s)', fieldName: 'timeframe', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }  },
    { label: 'Destination', fieldName: 'destination', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }  },
    { label: 'Truck', fieldName: 'timeframe', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }  },
    { label: 'Pickups', fieldName: 'pickups', type: 'number', fixedWidth: 130, hideDefaultActions: true, cellAttributes: { alignment: 'center' }  },
    { label: 'Deliveries', fieldName: 'deliveries', type: 'number', fixedWidth: 130, hideDefaultActions: true, cellAttributes: { alignment: 'center' }  },
    { label: 'Full', fieldName: 'full', type: 'number', fixedWidth: 130, hideDefaultActions: true, cellAttributes: { alignment: 'center' }  },
];
export default class TripTabComponent extends NavigationMixin(LightningElement) {
    userId = userId;
    defaultTabId = '';
    columns_pending = COLUMNS_PENDING;
    columns = COLUMNS;
    hasLoaded = false;
    @track tabs = [];
    navigateToNewTripPage() {
        this[NavigationMixin.Navigate]({
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Trip__c',
                actionName: 'new'
            },
        });
    }
    handleRowClick(event){
        const row = event.detail.row;
        this.navigateToRecord(row.id);
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

    //get locations
    @wire(getLocations)
    locationData({ error, data }) {
        if (data) {
            this.error = undefined;
            this.tabs = JSON.parse(JSON.stringify(data));
            console.log(this.tabs);
            console.log(this.tabs[0]);
            console.log(JSON.stringify(data));
            this.hasLoaded = true;
        } else if (error) {
            this.error = error;
            console.log(error);
            this.hasLoaded = true;
        }
    }
    //get default tab
    @wire(getRecord, { recordId: '$userId', fields: ['User.LastSelectedTripTabId__c'] })
    record({ error, data }) {
        if (data) {
            this.error = undefined;
            //set location name
            this.defaultTabId = getFieldValue(data, 'User.LastSelectedTripTabId__c');
            this.hasLoaded = true;
        } else if (error) {
            this.error = error;
            console.log(this.error)
        }
    }
    handleTabActive(event){
        const newTabId = event.target.value;
        if(this.defaultTabId == null){
            return;
        }
        console.log(`Tab ${event.target.value} is now active`);
        let fields = {
            LastSelectedTripTabId__c: newTabId,
            Id: this.userId
        }
        const recordInput = { fields }
        updateRecord(recordInput).then(() => {

        }).catch(error => {
            console.log(error);
        });

    }
    
}