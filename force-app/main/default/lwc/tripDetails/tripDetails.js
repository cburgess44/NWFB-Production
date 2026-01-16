/**
 * Created by dudunato on 23/10/22.
 */

import {api, LightningElement, track} from 'lwc';
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

export default class TripDetails extends LightningElement {
    @api
    selectedTrip;

    @track
    tripModified = false;

    @track
    stopList = [];

    @track
    servicesToAdd = [];

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
    urlCustomMap = window.location.origin;

    @track
    stopTimeValue = 15;

    @track
    showCustomMap = false;

    @track
    mapStops = [];

    @track
    mapMarkers = [];

    @track
    newStops = [];

    stopByServices = {};
    loading = false;

    @api
    async setSelectedServices(value, isLoading) {
        this.isLoading = isLoading;

        this.servicesToAdd = value;
        await this.handleServiceChange(value);

        setTimeout(() => {
            this.isLoading = false;
        }, 1000);
    }

    tripFields = {
        PTFRAME_FIELD,
        NAME_FIELD,
        TRUCK_FIELD,
        LOCATION_FIELD,
        CONTACT_FIELD,
        // DRIVER_FIELD,
        ORIGIN_FIELD,
        DESTINATION_FIELD,
        FULL_FIELD,
        DATE_FIELD,
        STATUS_FIELD,
        CALCULATEDTOTALTIMEMINUTES_FIELD,
        TOTAL_STOP_TIME_FIELD,
        GOOGLE_ROUTE_TIME_FIELD
    };

    showNewStopForm = false;

    async connectedCallback() {
        this.servicesToAdd = [];
        this.newStops = [];
        this.skipClose = false;
        await this.loadRelatedStops();
        await this.getGoogleMapsURL(false);
    }

    async handleServiceChange(value) {
        this.newStops = [];
        this.stopByServices = {};
        this.showNewStopForm = false;

        const event = new CustomEvent('stoploaded', {
            detail: {
                isLoading: false
            }
        });

        this.dispatchEvent(event);

        const values = value.flat();
        console.log('values', value);
        if (!values || values.length === 0) return;

        values.forEach((service, index) => {
             console.log('service', service.Contact__c);
             console.log('service', service.customerName);
            this.stopByServices[service.Id] = {
                sobjectType: 'Stop__c',
                Customer__c: service.Contact__c,
                CustomerName: service.customerName,
                Name: service.Address__c ? service.Address__c : '',
                Address__c: service.Address__c ? service.Address__c : '',
                StateProvince__c: service.State__c ? service.State__c : '',
                City__c: service.City__c ? service.City__c : '',
                Country__c: service.Country__c ? service.Country__c : '',
                PostalCode__c: service.Zip__c ? service.Zip__c : '',
                NumberOfItems__c: service.nOfItems,
                ServiceStatus__c: service.Status__c,
                Service__c: service.Id,
                ExtraTime__c: 0,
                StopOrder__c: index + 1 + this.stopList.length,
                Trip__c: this.selectedTrip?.Id,
                StopTime__c: this.stopTimeValue ? this.stopTimeValue : '',
                Marker_Color__c: service.Color__c,
                items: service.children ? [service.children] : []
            };
        });

        this.newStops = Object.values(this.stopByServices);
        this.showNewStopForm = true;
    }

    handleExtraTime(event) {
        let index = event.currentTarget.dataset.index;
        this.newStops[index].ExtraTime__c = event.target.value;
    }

    async handleCreateNewStop() {
        this.isLoading = true;
        const pendingServices = [];

        for (let serviceId of Object.keys(this.stopByServices)) {
            pendingServices.push({
                sobjectType: 'Service__c',
                Id: serviceId,
                Trip__c: this.stopByServices[serviceId].Trip__c
            });
        }

        if (pendingServices.length > 0) {
            const savedServices = await saveSObjects({sObjects: pendingServices});
            const pendingStops = [];

            if (savedServices.length > 0) {
                try {
                    for (const s of this.newStops) {
                        const newStop = {...s};
                        delete newStop.ServiceStatus__c;
                        delete newStop.items;
                        delete newStop.CustomerName;

                        newStop.sobjectType = 'Stop__c';
                        pendingStops.push(newStop);
                    }

                    const savedStop = await saveSObjects({sObjects: pendingStops});
                    const pendingServiceItems = [];

                    for (const s of this.newStops) {
                        const currentItems = s.items;
                        const serviceStatus = s.ServiceStatus__c;

                        for (const item of currentItems[0]) {
                            if ((serviceStatus === 'Re-Delivery' && (item.realItem.Status__c === 'Not Available' || item.realItem.Status__c === 'Declined'))
                                || serviceStatus !== 'Re-Delivery') {

                                pendingServiceItems.push({
                                    sobjectType: 'ServiceItem__c',
                                    Id: item['realItem'].Id,
                                    Stop__c: savedStop[0].Id
                                });
                            }
                        }
                    }

                    await saveSObjects({sObjects: pendingServiceItems});
                } catch (e) {
                    console.error('Error: ', e);
                }
            }
        }

        if (!this.skipClose) {
            this.handleCancel();
            await this.loadRelatedStops();
        } else {
            this.dispatchEvent(new CustomEvent('cleanselection'));
            await this.connectedCallback();
            await this.loadRelatedStops();
        }
        this.isLoading = false;
    }

    handleTripChange() {
        this.tripModified = true;
    }

    async handleSuccessTrip() {
        this.showSuccessToast();
        await this.handleCreateNewStop();
    }

    showSuccessToast() {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'The trip was Successfully updated',
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }

    async handleSave() {
        this.isLoading = true; 
        this.skipClose = true;
        const btn = this.template.querySelector('.save-and-close');
        await this.handleOptimize();
        if (btn) btn.click();
    }

    handleCancel() {
        this.stopList = null;
        this.servicesToAdd = null;
        this.isLoading = false;
        this.dispatchEvent(new CustomEvent('cancel'));
    }

    async handleStopExtraTimeBlur(event) {
        let stopId = event.currentTarget.dataset.targetId;
        let extraTime = event.target.value;

        let stopToUpdate = {};

        if (!stopId || !extraTime) return;

        this.isLoading = true;

        stopToUpdate = {
            sobjectType: 'Stop__c',
            Id: stopId,
            ExtraTime__c: extraTime
        };

        const updatedStop = await saveSObjects({sObjects: [stopToUpdate]});

        if (!updatedStop || updatedStop.length === 0) return;

        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'The Stop was Successfully Updated',
            variant: 'success'
        });

        this.dispatchEvent(evt);
        await refreshApex(this.newStops);
        await this.loadRelatedStops();
        this.isLoading = false;
    }

    async loadRelatedStops() {
        try {
            this.stopList = [];

            const filter = `AND Trip__c = '${this.selectedTrip.Id}' ORDER BY StopOrder__c`;
            const stops = await listSobjects({
                objectName: 'Stop__c',
                fields: [
                    'Id',
                    'Trip__c',
                    'PostalCode__c',
                    'City__c',
                    'Name',
                    'Customer__c',
                    'ServiceStatus__c',
                    'Customer__r.Name',
                    'StateProvince__c',
                    'Service__r.RecordType.DeveloperName',
                    'Service__r.SubType__c',
                    'Address__c',
                    'TotalTime__c',
                    'TravelTime__c',
                    'NumberOfItems__c',
                    'StopOrder__c',
                    'StopTime__c',
                    'Marker_Color__c',
                    'ExtraTime__c'
                ],
                filters: filter
            });

            if (stops === null) return;

            this.stopList = stops.map((stop) => {
                return {
                    ...stop,
                    CustomerName: stop.Customer__c ? stop.Customer__r.Name : ''
                }
            });

            this.dispatchEvent(new CustomEvent('loadrelatedstops'));
            this.generateMapMarkers(this.stopList);
        } catch (e) {
            console.error('Error: ', e);
        }
    }

    generateMapMarkers(stopList) {
        this.mapMarkers = [];
        if (!stopList || stopList.length === 0) return;

        stopList.forEach((element) => {
            let marker = {};
            const serviceRecordType = element.Service__r.RecordType.DeveloperName;
            const serviceSubType = element.Service__r.SubType__c;
            let mapColor = '';

            if (serviceRecordType === 'ClientRequest') {
                mapColor = 'red';
            } else if (serviceRecordType === 'DonationPickup') {
                mapColor = 'blue';
            } else if (serviceRecordType === 'GeneralDelivery' && serviceSubType === 'Hope Del.') {
                mapColor = 'purple';
            } else if (serviceRecordType === 'GeneralDelivery' && serviceSubType !== 'Hope Del.') {
                mapColor = 'orange';
            }

            marker['location'] = {
                City: element.City__c ? element.City__c : '',
                Country: element.Country__c ? element.Country__c : '',
                PostalCode: element.PostalCode__c ? element.PostalCode__c : '',
                StateProvince__c: element.StateProvince__c ? element.StateProvince__c : '',
                Street: element.Address__c ? element.Address__c : ''
            };

            if (element.Name) marker['title'] = element.Name;

            marker['mapIcon'] = {
                path: 'M 125,5 155,90 245,90 175,145 200,230 125,180 50,230 75,145 5,90 95,90 z',
                fillColor: mapColor,
                fillOpacity: 0.8,
                strokeWeight: 0,
                scale: 0.1,
                anchor: {x: 122.5, y: 115},
            };

            this.mapMarkers.push(marker);
        });
        this.zoomLevel = 6;
    }

    DragStart(event) {
        this.dragStart = event.target.title;
        event.target.classList.add('drag');
    }

    DragOver(event) {
        event.preventDefault();
        return false;
    }

    async Drop(event) {
        this.loading = true;
        event.stopPropagation();
        const DragValName = this.dragStart;
        const DropValName = event.target.title;

        if (DragValName === DropValName) {
            this.loading = false;
            return false;
        }

        const currentIndex = DragValName;
        const newIndex = DropValName;

        Array.prototype.move = function (from, to) {
            this.splice(to, 0, this.splice(from, 1)[0]);
        };

        this.stopList.move(currentIndex, newIndex);
        await this.saveStopInOrder(this.stopList);
        await this.getGoogleMapsURL(false);
        this.showReordertoast();
        this.loading = false;
    }

    async saveStopInOrder(stops) {
        try {
            stops.forEach((stop, index) => {
                const newIndex = Number(index) + 1;
                stop.sobjectType = 'Stop__c';
                stop.StopOrder__c = newIndex;
            });

            await saveSObjects({sObjects: stops});

            stops.sort((a, b) =>  a.StopOrder__c - b.StopOrder__c);
            this.stopList = stops;
        } catch (e) {
            console.error('Error: ', e);
        }
    }

    async removeRow(event) {
        this.isLoading = true;
        let stopId = event.target.value;
        await this.removeStop(stopId);
    }

    async removeStop(stopId) {
        try {
            this.isLoading = true;

            await this.disassociateServices(stopId);

            await deleteSObjects({sObjects: [{
                    sobjectType: 'Stop__c',
                    Id: stopId
            }]});

            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: 'The Stop was Successfully Deleted',
                variant: 'success'
            }));

            this.stopList = this.stopList.filter((stopList) => stopList.Id !== stopId)
            this.dispatchEvent(new CustomEvent('loadrelatedstops'));
            await this.reorderStopsOnTrip();

            this.isLoading = false;
        } catch (e) {
            console.error('Error: ', e);
            this.isLoading = false;
        }
    }

    async reorderStopsOnTrip() {
        try {
            this.stopList.forEach((stop, index) => {
                stop.StopOrder__c = index + 1;
            });

            await saveSObjects({sObjects: this.stopList});
        } catch (e) {
           console.error('Error: ', e);
        }
    }

    async disassociateServices(stopId) {
        this.isLoading = true;

        try {
            const serviceItems = await listSobjects({
                objectName: 'ServiceItem__c',
                fields: ['Id', 'Stop__c', 'Service__c'],
                filters: `AND Stop__c = '${stopId}'`
            });

            if (serviceItems.length === 0) return;
            let request = serviceItems[0].Service__c;

            const services = await listSobjects({
                objectName: 'Service__c',
                fields: ['Id', 'Trip__c', 'Stop__c'],
                filters: `AND Id = '${request}'`
            });

            if (services === null || services.length === 0) return;

            services.forEach((service) => {
                service.Trip__c = null;
            });

            await saveSObjects({sObjects: services});
        } catch (e) {
           console.error('Error: ', e);
        }
    }

    async handleOptimize() {
        this.showCustomMap = true;
        this.isLoading = true;

        try {
            await this.getGoogleMapsURL(true);
            this.showReordertoast();

            this.isLoading = false;
            this.showHideMapButton = true;
        } catch (error) {
            console.error('error ' + error);
            this.isLoading = false;
        }
    }

    parseURL(url) {
        url = url.split('%20').join('+');
        url = url.split('%7C').join('|');
        url = url.split('%2C').join(',');
        return url;
    }

    showReordertoast() {
        const evt = new ShowToastEvent({
            title: 'Success',
            message: 'The Stop order was Successfully Updated',
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }

    handleHideRoute() {
        this.showCustomMap = false;
        this.showHideMapButton = false;
    }

    async getGoogleMapsURL(optimize) {
        try {
            this.showCustomMap = true;
            const iframeUrl = await getIframeMapsUrl({
                originUrl: window.location.origin,
                stops: this.stopList,
                destination: this.selectedTrip.Location__r.Address__c,
                optimize: optimize
            });

            this.urlCustomMap = this.parseURL(iframeUrl);
            // await this.loadRelatedStops();
        } catch (e) {
           this.showCustomMap = false;
           console.error('Error: ', e);
        }
    }

    navigateToRecordPage() {
        let sfdcBaseURL = window.location.origin+'/'+this.selectedTrip.Id;
        window.open(sfdcBaseURL);
    }
}