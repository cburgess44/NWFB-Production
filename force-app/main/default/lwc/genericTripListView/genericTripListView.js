import { LightningElement, wire, track, api } from 'lwc';
import getLocations from '@salesforce/apex/GenericTripListViewController.getLocations';
const COLUMNS = [
    { label: 'Date', fieldName: 'tripDate', type: 'date',typeAttributes:{
        month: "2-digit",
        day: "2-digit",
        year: "2-digit",
    }, hideDefaultActions: true, fixedWidth: 160, cellAttributes: { alignment: 'left' } },
    { label: 'Timeframe(s)', fieldName: 'timeframe', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }  },
    { label: 'Destination', fieldName: 'destination', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }  },
    { label: 'Truck', fieldName: 'truckName', type: 'text', hideDefaultActions: true, cellAttributes: { alignment: 'left' }  },
    { label: 'Pickups', fieldName: 'pickups', type: 'number', fixedWidth: 130, hideDefaultActions: true, cellAttributes: { alignment: 'center' }  },
    { label: 'Deliveries', fieldName: 'deliveries', type: 'number', fixedWidth: 130, hideDefaultActions: true, cellAttributes: { alignment: 'center' }  },
    { label: 'Full', fieldName: 'full', type: 'number', fixedWidth: 130, hideDefaultActions: true, cellAttributes: { alignment: 'center' }  },
];
export default class GenericTripListView extends LightningElement {
    @api recordId;
    @api sObjectApiName;
    @api filters;
    @track tab;
    columns = COLUMNS;
    error;
    hasLoaded;
    //get locations
    @wire(getLocations, { recordId: '$recordId', sObjectApiName: '$sObjectApiName' , filters: '$filters'})
    locationData({ error, data }) {
        if (data) {
            this.error = undefined;
            this.tab = JSON.parse(JSON.stringify(data));
            console.log(JSON.parse(JSON.stringify(data)));
            this.hasLoaded = true;
        } else if (error) {
            this.error = error;
            console.log(error);
            this.hasLoaded = true;
        }
    }
}