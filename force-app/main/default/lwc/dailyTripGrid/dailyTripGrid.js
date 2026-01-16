/**
 * Created by dudunato on 15/10/22.
 */

import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PTFRAME_FIELD from '@salesforce/schema/Trip__c.PrimaryTimeframe__c';
import NAME_FIELD from '@salesforce/schema/Trip__c.Name';
import CUSTOMNAME_FIELD from '@salesforce/schema/Trip__c.CustomName__c';
import COPILOT1_FIELD from '@salesforce/schema/Trip__c.CoPilot1__c';
import COPILOT2_FIELD from '@salesforce/schema/Trip__c.CoPilot2__c';
import TRUCK_FIELD from '@salesforce/schema/Trip__c.Truck__c';
import FULL_FIELD from '@salesforce/schema/Trip__c.Full__c';
import CONTACT_FIELD from '@salesforce/schema/Trip__c.Contact__c';
import DRIVER_FIELD from '@salesforce/schema/Trip__c.Driver__c';
import ORIGIN_FIELD from '@salesforce/schema/Trip__c.Origin__c';
import DESTINATION_FIELD from '@salesforce/schema/Trip__c.Destination__c';
import DATE_FIELD from '@salesforce/schema/Trip__c.Date__c';
import STATUS_FIELD from '@salesforce/schema/Trip__c.Status__c';
import LOCATION_FIELD from '@salesforce/schema/Trip__c.Location__c';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';
import listSobjects from '@salesforce/apex/SObjectCRUDController.listSObjects';
import { refreshApex } from '@salesforce/apex';
import {dates} from 'c/generalUtilities'

export default class DailyTripGrid extends LightningElement {
    @api
    dailyTrips;
    
    @api
    selectedLocation;

    @track
    showTripModal = false;

    @track
    primaryTimeFrame;

    @track
    newTripDate;

    @track
    finalName;

    tripFields = {
        PTFRAME_FIELD,
        NAME_FIELD,
        TRUCK_FIELD,
        LOCATION_FIELD,
        CONTACT_FIELD,
        DRIVER_FIELD,
        ORIGIN_FIELD,
        DESTINATION_FIELD,
        FULL_FIELD,
        DATE_FIELD,
        STATUS_FIELD,
        CUSTOMNAME_FIELD,
        COPILOT1_FIELD,
        COPILOT2_FIELD
    };

    connectedCallback() {	
        console.log('cmp on CCB loaded');
    }

    handleTripSelection(event) {

        const timeFrame = event.currentTarget.dataset.name;
        const indexItem = event.currentTarget.dataset.index;
        let selectedRecord = {};

        selectedRecord = timeFrame === 'Morning' ? this.dailyTrips.morningTrips[indexItem] : this.dailyTrips.afternoonTrips[indexItem];

        if(event.target.type !== "checkbox"){
            this.dispatchEvent(
                new CustomEvent('selected', {
                    detail: {selectedRecord: selectedRecord, showCheckboxes: true}
                })
            );
        }

    }

    async markfullOnTrip(event){
        const timeFrame = event.currentTarget.dataset.name;
        const indexItem = event.currentTarget.dataset.index;
        let selectedRecord = {};

        selectedRecord = timeFrame === 'Morning' ? this.dailyTrips.morningTrips[indexItem] : this.dailyTrips.afternoonTrips[indexItem];
        
        let recordToUpdate = {
            sobjectType: 'Trip__c',
                Id: selectedRecord.Id,
                Full__c: event.target.checked
        };
        console.log('recordToUpdate   =>>>> ', recordToUpdate);
        const result =  await saveSObjects({
            sObjects: [recordToUpdate]
        });
        console.log('result ', result);
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'The trip was Successfully Updated',
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }

    async handleSuccessTrip() {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'The trip was Successfully created',
            variant: 'success'
        });
        this.dispatchEvent(evt);
        this.showTripModal = false;
        this.dispatchEvent(new CustomEvent('aftersuccess'));
        await refreshApex(this.dailyTrips);
    }

    handleAddTrip(event) {
        console.log('Clicked method, date:');
        console.log(event.currentTarget.dataset.date);
        this.showTripModal = true;
        let obj = event.target.value;
        this.primaryTimeFrame = event.currentTarget.dataset.name;
        console.log('Time frame after clicking plus button ', event.currentTarget.dataset.name);

        //This dates.sfDate function is no longer necessary because we are already converting the date to the SF standard before sending it to this component.
        //this.newTripDate = dates.sfDate(new Date(event.currentTarget.dataset.date));
        this.newTripDate = event.currentTarget.dataset.date;
    }
    closemodal() {
        this.showTripModal = false;
    }

    // setFinalName(event) {
    //     let obj = event.target.value;
    //     this.finalName = event.target.value.Name + ' ' + newTripDate;
        
    // }

}