/**
 * Created by Eric on 17/04/2023.
 */

import { LightningElement, api, track, wire } from 'lwc';
import PTFRAME_FIELD from '@salesforce/schema/Trip__c.PrimaryTimeframe__c';
import NAME_FIELD from '@salesforce/schema/Trip__c.Name';
import FULL_FIELD from '@salesforce/schema/Trip__c.Full__c';
import TRUCK_FIELD from '@salesforce/schema/Trip__c.Truck__c';
import LOCATION_FIELD from '@salesforce/schema/Trip__c.Location__c';
import CONTACT_FIELD from '@salesforce/schema/Trip__c.Contact__c';
import DRIVER_FIELD from '@salesforce/schema/Trip__c.Driver__c';
import ORIGIN_FIELD from '@salesforce/schema/Trip__c.Origin__c';
import DESTINATION_FIELD from '@salesforce/schema/Trip__c.Destination__c';
import DATE_FIELD from '@salesforce/schema/Trip__c.Date__c';
import CALCULATEDTOTALTIMEMINUTES_FIELD from '@salesforce/schema/Trip__c.CalculatedTotalTimeMinutes__c';
import TOTAL_STOP_TIME_FIELD from '@salesforce/schema/Trip__c.TotalStopTime__c';
import GOOGLE_ROUTE_TIME_FIELD from '@salesforce/schema/Trip__c.GoogleRouteTime__c';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {refreshApex} from '@salesforce/apex';
import listSobjects from '@salesforce/apex/SObjectCRUDController.listSObjects';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';
import deleteSObjects from '@salesforce/apex/SObjectCRUDController.deleteSObjects';
import STATUS_FIELD from '@salesforce/schema/Trip__c.Status__c';

import callMapDirections from '@salesforce/apex/MapsAPICallout.callMapDirections';
import getIframeMapsUrl from '@salesforce/apex/GoogleMapsAPIController.getIframeMapsUrl';


import {getRecord} from 'lightning/uiRecordApi';

export default class StopMap extends LightningElement {
    @api
    recordId;

    @api
    selectedTrip;

    @track
    tripModified = false;

    @track
    stopList = [];

    @track
    servicesToAdd = [];

    @track
    newStops;

    @track
    googleRouteTime;

    @track
    totalStopTime;

    @track
    calculatedTotalTime;

    @track
    dragStart;

    @track
    showHideMapButton = false;

    @track
    skipClose;

    @track
    center = [];

    @track
    zoomLevel = [];

    @track
    isLoading;

    @track
    urlCustomMap = '';

    @track
    stopTimeValue = 15;

    @track
    showCustomMap = false;

    @track
    mapStops = [];

    @track
    mapMarkers = [];

    async connectedCallback() {
       await this.fetchTripData();
       this.servicesToAdd = [];
       this.newStops = [];
       this.skipClose = false;
       await this.loadRelatedStops();
       await this.getGoogleMapsURL(false);
    }

    async getGoogleMapsURL(optimize) {
        try {
            this.showCustomMap = true;
            const iframeUrl = await getIframeMapsUrl({
                originUrl: window.location.origin,
                stops: this.stopList,
                destination: this.selectedTrip?.Location__r?.Address__c,
                optimize: optimize
            });

            if (!iframeUrl) return;
            this.urlCustomMap = this.parseURL(iframeUrl);
            await this.loadRelatedStops();
        } catch (e) {
            console.error('Error: ', JSON.stringify(e));
        }
    }

    async fetchTripData(){
       try {
           const filter = `AND Id ='${this.recordId}'`;

           const tripRecord = await listSobjects({
               objectName: 'Trip__c',
               fields:['Id', 'Location__c', 'Location__r.Address__c'],
               filters: filter
           });

           this.selectedTrip = tripRecord[0];
       } catch (e) {
            console.error('Error: ', e) ;
       }
    }

    async loadRelatedStops() {
        try {
            this.stopList = [];
            const filter = `AND Trip__c = '${this.recordId}' ORDER BY StopOrder__c`;

            const stops = await listSobjects({
                objectName: 'Stop__c',
                fields: [
                    'Id',
                    'Trip__c',
                    'PostalCode__c',
                    'City__c',
                    'Name',
                    'Customer__c',
                    'Customer__r.Name',
                    'StateProvince__c',
                    'Address__c',
                    'TotalTime__c',
                    'TravelTime__c',
                    'NumberOfItems__c',
                    'Service__r.SubType__c',
                    'Service__r.RecordType.DeveloperName',
                    'StopOrder__c',
                    'StopTime__c',
                    'Marker_Color__c'
                ],
                filters: filter
            });

            if (stops === null) return;
            this.stopList = stops;

            this.generateMapMarkers(this.stopList);
        } catch (e) {
           console.error('Error: ', e);
        }
    }

    generateMapMarkers(stopList) {
       this.mapMarkers = [];

       stopList.forEach((element) => {
           const location = {
               City: element.City__c ? element.City__c : '',
               Country: element.Country__c ? element.Country__c : '',
               PostalCode: element.PostalCode__c ? element.PostalCode__c : '',
               StateProvince__c: element.StateProvince__c ? element.StateProvince__c : '',
               Street: element.Address__c ? element.Address__c : ''
           };

           const serviceRecordType = element.Service__r.RecordType.DeveloperName;
           const serviceSubType = element.Service__r.SubType__c;
           let mapColor = '';

           if (serviceRecordType === 'ClientRequest') {
               mapColor = 'red';
           } else if (serviceRecordType === 'DonationPickup') {
               mapColor = 'blue';
           } else if (serviceRecordType === 'GeneralDelivery' && serviceSubType === 'Hope Del.') {
               mapColor = 'purple';
           }

           const mapIcon = {
               path: 'M 125,5 155,90 245,90 175,145 200,230 125,180 50,230 75,145 5,90 95,90 z',
               fillColor: mapColor,
               fillOpacity: 0.8,
               strokeWeight: 0,
               scale: 0.1,
               anchor: {x: 122.5, y: 115},
           }

           const marker = {
               location: location,
               mapIcon: mapIcon,
           };

           if (element.Name) marker['title'] = element.Name;
           this.mapMarkers.push(marker);
       });

       this.zoomLevel = 6;
    }


    parseURL(url) {
       url = url.split('%20').join('+');
       url = url.split('%7C').join('|');
       url = url.split('%2C').join(',');
       return url;
    }

    parseTripDurationToString(num) {
       let hours = Math.round(num / 60);
       let minutes = num % 60;
       let finalString = hours != 0 ? +"h, " + minutes + " min" : minutes + " min";
       return finalString;
    }

}