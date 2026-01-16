/**
 * Created by dudunato on 15/10/22.
 */

import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { twoWeeksDateRange, moveTwoWeeks, setOldTrips } from './helper';
import { dates } from 'c/generalUtilities';
import { SERVICES_COLUMNS, PICKUP_COLUMNS, PICKUP_ITEM_COLUMNS, MOCK_DATA } from './constants';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import listSobjects from '@salesforce/apex/SObjectCRUDController.listSObjects';
import getCustomSettings from '@salesforce/apex/SObjectCRUDController.getCustomSettings';
import userId from '@salesforce/user/Id';
import saveSObjects from "@salesforce/apex/SObjectCRUDController.saveSObjects";


export default class DispatchTrips extends LightningElement {

    @api
    recordId;

    @api
    objectApiName;

    @track
    showPrevious = true;

    @track 
    showDetails = false;

    @track
    currentDateRange;

    @track
    structuredTrips = [];

    @track
    selectedLocation = '';

    @track
    pickupServices;

    @track
    parentPickupData;

    @track
    generalDeliveryClickProcess = false;

    @track
    generalPickupClickProcess = false;

    @track
    donationPickupClickProcess = false;

    @track
    hasOldTrips = false;

    @track
    deliveryServices;

    @track
    selectedTrip;

    @track
    loading;

    @track
    locationOptions = [];

    @track
    selectedServices = [];

    @track
    setSelectedRows = [];

    @track
    showConfirmationTab = false;

    keepTripDetailsOpened = false;
    currentOnPreviousTrips = false;
    initialDateRange;
    trip;
    tripData;
    groupedTrips;
    groupedClosedTrips;
    groupedOldTrips;
    locations = '';
    servicesColumns;
    pickupColumns;
    saveListener;
    childrenColumns;
    firstOldDate;
    lastOldDate;
    

    @wire(getObjectInfo, { objectApiName: 'Service__c' })
    objectInfo;

    @wire(getCustomSettings)
    nwfbSettings;


    async connectedCallback() {
        this.initValues();
        await this.initFunctions();
    }

    initValues() {
        this.structuredTrips = [];
        this.servicesColumns = SERVICES_COLUMNS;
        this.pickupColumns = PICKUP_COLUMNS;
        this.childrenColumns = PICKUP_ITEM_COLUMNS;
        this.currentDateRange = twoWeeksDateRange(new Date());
        this.showPrevious = false;
        this.selectedTrip = !this.keepTripDetailsOpened ? null : this.selectedTrip;

        this.pickupServices = [];
        this.parentPickupData = [];
        this.deliveryServices = [];
        this.tripData = [];
        this.groupedTrips = {};
        this.groupedClosedTrips = {};
        this.loading = false;

    }

    async initFunctions() {
        this.loading = true;
        await this.loadUserDefaultLocation();
        await this.getLocations();
        await this.loadAvailableServices(this.selectedLocation);
        await this.loadCurrentTrips(this.selectedLocation, false, false);
        await this.loadCurrentTrips(this.selectedLocation, true, true);
        await this.loadPastOpenTrips(this.selectedLocation, this.formattedDate(new Date()), true);
        this.loading = false;
    }

    async loadUserDefaultLocation(){
        if (this.keepTripDetailsOpened) return;
        try {
            const filter = `AND User__c = '${userId}' AND main__c = true`;

            const defaultUserLocation = await listSobjects({
                objectName: 'User_Location__c',
                fields:['Id', 'Location__c', 'main__c', 'User__c'],
                filters:filter
            });

            if (defaultUserLocation.length === 0) return;

            this.selectedLocation = defaultUserLocation[0].Location__c;
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    async handleMarkServiceAsOnHold(event) {
        try {
            this.loading = true;
            const serviceId = event.target.value;
            const isChecked = event.target.checked;

            if (!serviceId) {
                this.loading = false;
                return;
            }

            await saveSObjects({
                sObjects: [{
                    Id: serviceId,
                    OnHold__c: isChecked
                }]
            });

            this.loading = false;
        } catch (e) {
           console.error('Error marking service as on hold ' + e);
        }
    }

    async loadAvailableServices(selectedLocation) {
        try {
            const filter = `AND Trip__c = NULL AND Location__c = '${selectedLocation}' AND RecordTypeId != NULL AND Status__c ='Routing'`;
            const services = await listSobjects({
                objectName: 'Service__c',
                fields: [
                    'Id',
                    'Name',
                    'Stop__c',
                    'Total_Items__c',
                    'Contact__c',
                    'Area__r.Name',
                    'Accessibility__c',
                    'Caseworker__r.Name',
                    'Address__c',
                    'Contact__r.Name',
                    'Contact__r.Phone',
                    'LastAppointmentDate__c',
                    'Location__c',
                    'Trip__c ',
                    'State__c',
                    'City__c',
                    'Country__c',
                    'Zip__c',
                    'CreatedDate',
                    'RecordTypeId',
                    'RecordType.Name',
                    'SubType__c',
                    'Status__c',
                    'Pickup_type__c',
                    'Color__c',
                    'Pickup_Date_1__c',
                    'Pickup_Date_2__c',
                    'Pickup_Date_3__c',
                    'CheckPointColor__c',
                    'OnHold__c',
                    '(SELECT Id, Stop__c, Name, Status__c, Product__c,Quantity__c,Product__r.Name FROM ServiceItems__r)'
                ],
                filters: filter
            });

            this.mappingResponseToPickupServices(services);
            this.mappingResponseToDeliveryServices(services);

        } catch (e) {
           console.error('Error: ', e);
        }
    }

    async cleanSelection() {
        this.loading = true;
        this.keepTripDetailsOpened = true;
        this.setSelectedRows = [];
        this.selectedServices = [];
        await this.connectedCallback();
    }

    async getLocations() {
        try {
            const request = await listSobjects({
                objectName: 'Location__c',
                fields: ['Id', 'Name'],
                filters: 'AND Active__c = TRUE'
            });

            this.mapLocationOptions(request);
            this.setDefaultLocation(this.locationOptions);
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    setDefaultLocation(locationOptions) {
        if (this.selectedLocation || locationOptions.length === 0) return;
        this.selectedLocation = locationOptions[0].value;
    }

    mapLocationOptions(request) {
        this.locationOptions = request.map((location) => {
            return {
                label: location.Name,
                value: location.Id
            };
        });
    }

    mappingResponseToPickupServices(response) {
        this.pickupServices = [];
        this.parentPickupData = [];

        const filteredResponse = response.filter((service) => {
            if (!service.RecordTypeId) return;
            if (service.RecordType.Name !== 'Donation Pickup' && service.RecordType.Name !== 'General Pickup') return;
            return service;
        });

        filteredResponse.sort((a, b) => new Date(a.CreatedDate) - new Date(b.CreatedDate));
        filteredResponse.reverse();

        filteredResponse.forEach((service) => {
            const customerName = service.Contact__c ? service.Contact__r.Name : '';
            const caseworkerName = service.Caseworker__c ? service.Caseworker__r.Name : '';
            const areaName = service.Area__c ? service.Area__r.Name : '';
            const phone = service.Contact__c ? service.Contact__r.Phone : '';
            const children = [];

            if (service.ServiceItems__r && service.ServiceItems__r.length > 0) {
                service.ServiceItems__r.forEach((item) => {
                    children.push({
                        customerName: item.Name,
                        type: service.SubType__c,
                        name: item.Product__c != undefined? item.Product__r.Name: '',
                        quantity: item.Quantity__c,
                        realItem: item
                    });


                });
            }

            const tempService = {};

            tempService['isFirstIndex'] = filteredResponse.indexOf(service) === 0;

            const pickupFieldsAreNull = (!service.Pickup_Date_1__c && !service.Pickup_Date_2__c && !service.Pickup_Date_3__c);

            tempService['Id'] = service.Id;
            tempService['Name'] = service.Name;
            tempService['isExpanded'] = false;
            tempService['CheckPointColor__c'] = service.CheckPointColor__c;
            tempService['CreatedDate'] = service.CreatedDate;
            tempService['PickupDateOne'] = service.Pickup_Date_1__c;
            tempService['PickupDateTwo'] = service.Pickup_Date_2__c;
            tempService['PickupDateThree'] = service.Pickup_Date_3__c;
            tempService['areBothNull'] = (pickupFieldsAreNull && children.length === 0 );
            tempService['PickupFieldsAreNull'] = pickupFieldsAreNull;
            tempService['Phone'] = phone;
            tempService['RecordTypeName'] = service.RecordTypeId ? service.RecordType.Name : '';
            tempService['SubType__c'] = service.SubType__c ? service.SubType__c : '';
            tempService['Status__c'] = service.Status__c ? service.Status__c : '';
            tempService['Pickup_type__c'] = service.Pickup_type__c ? service.Pickup_type__c : '';
            tempService['customerName'] = customerName ? customerName : '';
            tempService['caseworkerName'] = caseworkerName ? caseworkerName : '';
            tempService['Location__c'] = service.Location__c ? service.Location__c : '';
            tempService['area'] = areaName;
            tempService['LastAppointmentDate__c'] = service.LastAppointmentDate__c ? service.LastAppointmentDate__c : '';
            tempService['Accessibility__c'] = service.Accessibility__c ? service.Accessibility__c : '';
            tempService['Contact__c'] = service.Contact__c ? service.Contact__c : '';
            tempService['Address__c'] = service.Address__c ? service.Address__c : '';
            tempService['City__c'] = service.City__c ? service.City__c : '';
            tempService['State__c'] = service.State__c ? service.State__c : '';
            tempService['Country__c'] = service.Country__c ? service.Country__c : '';
            tempService['Zip__c'] = service.Zip__c ? service.Zip__c : '';
            tempService['Color__c'] = service.Color__c;
            tempService['nOfItems'] = service.Total_Items__c;
            tempService['OnHold__c'] = service.OnHold__c;
            tempService['nOfItemsBiggerThan'] = service.Total_Items__c > 0;
            tempService['children'] = children;
            tempService['URL'] = '/'+service.Id;

            this.pickupServices.push(tempService);
        });

        this.pickupServices = [...this.pickupServices];
    }

    mappingResponseToDeliveryServices(response) {
        this.deliveryServices = [];
        const filteredResponse = response.filter((service) => {
            if (!service.RecordTypeId) return;
            if ((service.RecordType.Name === 'Client Request' || service.RecordType.Name === 'General Delivery') && service.Status__c === 'Routing'){
                return service;
            }
        });

        filteredResponse.sort((a, b) => {
            if (!a.LastAppointmentDate__c && !b.LastAppointmentDate__c) {
                return 0;
            } else if (!a.LastAppointmentDate__c) {
                return 1;
            } else if (!b.LastAppointmentDate__c) {
                return -1;
            } else {
                return new Date(a.LastAppointmentDate__c) - new Date(b.LastAppointmentDate__c);
            }
        });

        filteredResponse.forEach((service) => {
            const customerName = service.Contact__c ? service.Contact__r.Name : '';
            const caseworkerName = service.Caseworker__c ? service.Caseworker__r.Name : '';
            const phone = service.Contact__c ? service.Contact__r.Phone : '';
            const areaName = service.Area__c ? service.Area__r.Name : '';
            const children = [];

            if (service.ServiceItems__r && service.ServiceItems__r.length > 0) {
                service.ServiceItems__r.forEach((item) => {
                    children.push({
                        customerName: item.Name,
                        type: service.SubType__c,
                        name:item.Product__c != undefined ? item.Product__r.Name: '',
                        quantity: item.Quantity__c,
                        realItem: item
                    });
                });
            }

            const tempDelivery = {};

            tempDelivery['isFirstIndex'] = filteredResponse.indexOf(service) === 0;

            let pickupFieldsAreNull = (!service.Pickup_Date_1__c && !service.Pickup_Date_2__c && !service.Pickup_Date_3__c);

            tempDelivery['Id'] = service.Id;
            tempDelivery['Name'] = service.Name;
            tempDelivery['isExpanded'] = false;
            tempDelivery['CheckPointColor__c'] = service.CheckPointColor__c;
            tempDelivery['PickupDateOne'] = service.Pickup_Date_1__c;
            tempDelivery['PickupDateTwo'] = service.Pickup_Date_2__c;
            tempDelivery['PickupDateThree'] = service.Pickup_Date_3__c;
            tempDelivery['areBothNull'] = (pickupFieldsAreNull && children.length === 0 );
            tempDelivery['PickupFieldsAreNull'] = pickupFieldsAreNull;
            tempDelivery['RecordTypeName'] = service.RecordTypeId !== undefined ? service.RecordType.Name : '';
            tempDelivery['SubType__c'] = service.SubType__c !== undefined ? service.SubType__c : '';
            tempDelivery['Status__c'] = service.Status__c !== undefined ? service.Status__c : '';
            tempDelivery['Pickup_type__c'] = service.Pickup_type__c !== undefined ? service.Pickup_type__c : '';
            tempDelivery['customerName'] = customerName === undefined ? '' : customerName;
            tempDelivery['caseworkerName'] = caseworkerName;
            tempDelivery['Location__c'] = service.Location__c;
            tempDelivery['area'] = areaName;
            tempDelivery['LastAppointmentDate__c'] = service.LastAppointmentDate__c !== undefined ? service.LastAppointmentDate__c : '';
            tempDelivery['Accessibility__c'] = service.Accessibility__c !== undefined ? service.Accessibility__c : '';
            tempDelivery['Contact__c'] = service.Contact__c !== undefined ? service.Contact__c : '';
            tempDelivery['Address__c'] = service.Address__c !== undefined ? service.Address__c : '';
            tempDelivery['City__c'] = service.City__c !== undefined ? service.City__c : '';
            tempDelivery['State__c'] = service.State__c !== undefined ? service.State__c : '';
            tempDelivery['Country__c'] = service.Country__c !== undefined ? service.Country__c : '';
            tempDelivery['Zip__c'] = service.Zip__c !== undefined ? service.Zip__c : '';
            tempDelivery['Color__c'] = service.Color__c;
            tempDelivery['Phone'] = phone;
            tempDelivery['nOfItems'] = service.Total_Items__c;
            tempDelivery['OnHold__c'] = service.OnHold__c;
            tempDelivery['nOfItemsBiggerThan'] = service.Total_Items__c > 0;
            tempDelivery['children'] = children;
            tempDelivery['URL'] = '/'+service.Id;
            this.deliveryServices.push(tempDelivery);
        });

        this.deliveryServices = [...this.deliveryServices];
    }

    async loadPastOpenTrips(selectedLocation, currentDate, serialize) {
        try {
            this.loading = true;
            this.groupedOldTrips = [];
            let filter =`AND Date__c < ${currentDate} AND Location__c = '${selectedLocation}' AND PrimaryTimeframe__c != null 
            AND Status__c !='Closed' ORDER BY Date__c ASC`;

            const request = await listSobjects({
                objectName: 'Trip__c',
                fields: [
                    'Id',
                    'Date__c',
                    'PrimaryTimeframe__c',
                    'Name',
                    'Status__c',
                    'NotesForDriver__c',
                    'Driver__c',
                    'Driver__r.Name',
                    'Truck__r.Name',
                    'Location__c',
                    'Driver_Name_Truncate__c',
                    'Truck_Name_Truncate__c',
                    'NumberOfDeliveriesOnHOPE__c',
                    'NumberOfDeliveriesOnNWFB__c',
                    'NumberOfPickupsOnCORP__c',
                    'NumberOfPickupsOnNWFB__c',
                    'NumberOfPickupsOnSB__c',
                    'Location__r.Address__c',
                    'CalculatedTotalTimeMinutes__c',
                    'Full__c',
                    'TotalStopTime__c',
                    'GoogleRouteTime__c',
                    'CustomName__c',
                    'CoPilot1__c',
                    'CoPilot2__c'
                ],
                filters: filter
            });

            if (request === null) return;
            this.request = request[0];

            if (request.length > 0) {
                this.hasOldTrips = true;
                this.showPrevious = true;
                this.firstOldDate = new Date(request[0].Date__c);
                this.lastOldDate = new Date(request[request.length -1].Date__c);
            }

            let tripMaps = new Map();

            for (let trip of request) {
                let tripDate = trip.Date__c;

                if (!tripDate) continue;

                trip.class = trip.Status__c === 'Completed' ? 'completed' : 'grey';

                if (!tripMaps[trip.Date__c]) tripMaps[trip.Date__c] = [];

                if (!this.groupedOldTrips.hasOwnProperty(trip.Date__c)) {
                    this.groupedOldTrips[trip.Date__c] = {
                        afternoon: [],
                        morning: []
                    };
                }

                if (trip.PrimaryTimeframe__c === 'Morning') {
                    this.groupedOldTrips[tripDate].morning.push(trip);
                } else {
                    this.groupedOldTrips[tripDate].afternoon.push(trip);
                }
            }

            if (serialize) await this.serializeTripsPerDate();
            this.loading = false;
        } catch (e) {
           console.error('Error: ', e);
        }
    }

    async loadCurrentTrips(selectedLocation, getClosedTrips, serialize) {
        this.loading = true;

        this.tripData = [];

        let filter = `AND Date__c >= ${this.currentDateRange.firstDaySF} 
            AND Date__c <= ${this.currentDateRange.lastDaySF}
            AND Location__c  = '${selectedLocation}' 
            AND PrimaryTimeframe__c != NULL 
        `;

        filter += !getClosedTrips ? `AND Status__c != 'Closed'` : `AND Status__c ='Closed' `;

        if (!getClosedTrips) {
            this.groupedTrips = [];
        } else{
            this.groupedClosedTrips = [];
        }

        try {
            const request = await listSobjects({
                objectName: 'Trip__c',
                fields: [
                    'Id',
                    'Date__c',
                    'PrimaryTimeframe__c',
                    'Name',
                    'Status__c',
                    'NotesForDriver__c',
                    'Driver__c',
                    'Driver__r.Name',
                    'Truck__r.Name',
                    'Location__c',
                    'Driver_Name_Truncate__c',
                    'Truck_Name_Truncate__c',
                    'NumberOfDeliveriesOnHOPE__c',
                    'NumberOfDeliveriesOnNWFB__c',
                    'NumberOfPickupsOnCORP__c',
                    'NumberOfPickupsOnNWFB__c',
                    'NumberOfPickupsOnSB__c',
                    'Location__r.Address__c',
                    'CalculatedTotalTimeMinutes__c',
                    'CalculatedTotalTimeText__c',
                    'Full__c',
                    'TotalStopTime__c',
                    'GoogleRouteTime__c',
                    'CustomName__c',
                    'CoPilot1__c',
                    'CoPilot2__c'
                ],
                filters: filter
            });

            if (request === null) {
                this.loading = false;
                return;
            }

            this.request = request[0];
            let tripMaps = new Map();

            for (let trip of request) {
                if (!trip.Date__c) continue;

                const tripDate = trip.Date__c;

                trip.class = trip.Status__c === 'Completed' ? 'completed' : 'grey';

                if (!tripMaps[trip.Date__c]) tripMaps[trip.Date__c] = [];

                if (!getClosedTrips) {
                    if (!this.groupedTrips.hasOwnProperty(trip.Date__c)) {
                        this.groupedTrips[trip.Date__c] = {
                            afternoon: [],
                            morning: []
                        };
                    }

                    if (trip.PrimaryTimeframe__c === 'Morning') {
                        this.groupedTrips[tripDate].morning.push(trip);
                    } else {
                        this.groupedTrips[tripDate].afternoon.push(trip);
                    }

                    continue;
                }

                if (!this.groupedClosedTrips.hasOwnProperty(trip.Date__c)) {
                    this.groupedClosedTrips[trip.Date__c] = {
                        afternoon: [],
                        morning: []
                    };
                }

                if (trip.PrimaryTimeframe__c === 'Morning') {
                    this.groupedClosedTrips[tripDate].morning.push(trip);
                } else {
                    this.groupedClosedTrips[tripDate].afternoon.push(trip);
                }
            }

            if (serialize) await this.serializeTripsPerDate();
            this.loading = false;

        } catch (e) {
            console.error('Error: ', e);
        }
    }

    async handleDateRangeChange(event) {
        const action = event.target.value;

        switch (action) {
            case 'previous':
                if (this.hasOldTrips && this.formattedDate(this.currentDateRange.firstDay) === this.formattedDate(new Date())) {
                    this.currentDateRange = setOldTrips(dates.sfDate(this.firstOldDate), dates.sfDate(this.lastOldDate));
                    this.showPrevious = false;
                    this.currentOnPreviousTrips = true;
                } else {
                    this.currentDateRange = moveTwoWeeks(this.currentDateRange.firstDay, true);
                    this.currentOnPreviousTrips = false;
                    this.showPrevious = this.formattedDate(this.currentDateRange.firstDay) >= this.formattedDate(new Date());
                }

                break;

            case 'today':
                this.currentDateRange = twoWeeksDateRange(new Date());
                this.showPrevious = this.currentDateRange.firstDay > new Date();
                this.currentOnPreviousTrips = this.currentDateRange.firstDay > new Date();
                this.showPrevious = this.hasOldTrips;
                break;

            case 'next':
                if(this.currentOnPreviousTrips){
                    this.currentDateRange = twoWeeksDateRange(new Date());
                    this.currentOnPreviousTrips = false;
                } else {
                    this.currentDateRange = moveTwoWeeks(this.currentDateRange.lastDay);
                    this.currentOnPreviousTrips = this.currentDateRange.firstDay <= new Date();
                }

                this.showPrevious = true;
                break;
        }

        await this.loadAvailableServices(this.selectedLocation);
        await this.loadCurrentTrips(this.selectedLocation, false, false);
        await this.loadCurrentTrips(this.selectedLocation, true, true);
    }

    addDays(myDate, days) {
        return new Date(myDate.getTime() + days * 24 * 60 * 60 * 1000);
    }

    async getBlackoutDays() {
        let blockDay = {};

        let locationFilter = this.selectedLocation !== '' ? ` AND Location__c = '${this.selectedLocation}'` : '';
        const blackoutFilter =
            `AND Date__c >= ${this.currentDateRange.firstDaySF} AND Date__c <= ${this.currentDateRange.lastDaySF}` + locationFilter;
        const blackout = await listSobjects({
            objectName: 'DispatcherException__c',
            fields: [
                'Id',
                'Date__c',
                'Name',
                'RecordType.DeveloperName',
                'TimeFrame__c',
                'Area__c'
            ],
            filters: blackoutFilter
        });
        if (blackout !== null) {
            blackout.forEach(function (blackOutDay) {
                let blackoutObj = {};
                blackoutObj.name = blackOutDay.Name;
                blackoutObj.Type = blackOutDay.hasOwnProperty('RecordType') ? blackOutDay.RecordType.DeveloperName : '';
                blackoutObj.Timeframe =  blackOutDay.TimeFrame__c;
                blackoutObj.date = blackOutDay.Date__c;
                blockDay[blackOutDay.Date__c] = blackoutObj;
            });
        }


        return blockDay;
    }

    async serializeTripsPerDate() {
        const structuredTrips = [];
        let blackoutObj = await this.getBlackoutDays();

        for (
            let currentDate = new Date(this.currentDateRange.firstDaySF);
            currentDate <= new Date(this.currentDateRange.lastDaySF);
            currentDate = this.addDays(currentDate, 1)
        ) {
            let blackOutDay = blackoutObj.hasOwnProperty(this.formattedDate(currentDate))? blackoutObj[ this.formattedDate(currentDate)] : '';
            let isBlackOut = blackOutDay.hasOwnProperty(dates.sfDate(new Date(currentDate)));
            let isWholeDay;
            let isMorningBlocked;
            let isAfternoonBlocked;
            let showAnyway = blackOutDay.Type === 'Available';

            if (!this.groupedTrips.hasOwnProperty(this.formattedDate(currentDate)) && this.groupedClosedTrips.hasOwnProperty(this.formattedDate(currentDate)) && this.formattedDate(currentDate) < this.formattedDate(new Date())){
               continue;
            }

            if (showAnyway) {
                isAfternoonBlocked = blackOutDay.Timeframe === 'Morning';
                isMorningBlocked = blackOutDay.Timeframe === 'Afternoon';
            } else {
                isWholeDay = blackOutDay.Timeframe === 'Morning;Afternoon';
                isMorningBlocked = blackOutDay.Timeframe === 'Morning';
                isAfternoonBlocked = blackOutDay.Timeframe === 'Afternoon';
            }

            var addDay;

            if(!this.groupedTrips.hasOwnProperty(this.formattedDate(currentDate)) && this.formattedDate(currentDate) < this.formattedDate(new Date(new Date().setMonth(new Date().getMonth() - 1)))){
                addDay = false;
            } else if(showAnyway) {
                addDay = true;
            } else if(currentDate.getDay() !== 6 && currentDate.getDay() !== 0){
                addDay = true;
            } else {
                addDay = false;
            }

            if (addDay) {
                structuredTrips.push({
                    day: this.formattedDate(currentDate),
                    blackout: isBlackOut,
                    // timeFrame: blackOutDay.Timeframe,
                    morning: isMorningBlocked,
                    afternoon: isAfternoonBlocked,
                    allDay: isWholeDay,
                    morningTrips: this.groupedTrips[currentDate.toISOString().split('T')[0]] ? this.groupedTrips[currentDate.toISOString().split('T')[0]].morning : [],
                    afternoonTrips: this.groupedTrips[currentDate.toISOString().split('T')[0]] ? this.groupedTrips[currentDate.toISOString().split('T')[0]].afternoon : []
                });
            }
            
        }

        this.structuredTrips = structuredTrips;
    }

    showTripDetail(event) {
        this.selectedTrip = event.detail.selectedRecord;
    }

    async hideTripDetail() {
        this.selectedServices = [];
        this.setSelectedRows = [];
        this.selectedTrip = null;
    }

    async handleGeneralDeliveryClick() {
        this.generalDeliveryClickProcess = true;
    }

    handleGeneralPickupClick() {
        this.generalPickupClickProcess = true;
    }

    handleDonationPickupClick() {
        this.donationPickupClickProcess = true;
    }

    handleSuccessServiceCreation(event) {
        const message = event.target.value;
        const serviceId = event.detail.id;
        this.generalDeliveryClickProcess = false;
        const evt = new ShowToastEvent({
            title: 'Success',
            message: message,
            variant: 'success'
        });
        this.dispatchEvent(evt);
        window.location = `/lightning/r/Service__c/${serviceId}/view`;
    }

    closeModal() {
        this.generalDeliveryClickProcess = false;
        this.generalPickupClickProcess = false;
        this.donationPickupClickProcess = false;
    }

    async filterOptions(event) {
        this.selectedLocation = event.target.value;
        this.showPrevious = false;
        await this.loadAvailableServices(this.selectedLocation);
        await this.loadCurrentTrips(this.selectedLocation, false, false);
        await this.loadCurrentTrips(this.selectedLocation, true, true);
        await this.loadPastOpenTrips(this.selectedLocation, this.formattedDate(new Date()));
    }

    async handlerAfterSuccess(){
        this.keepTripDetailsOpened = true;
        await this.connectedCallback();
    }

    formattedDate (date) {
        let day = date.getUTCDate().toString();
        day = day.length > 1 ? day : '0' + day;
        let month = (date.getUTCMonth() + 1);

        if (month < 10) month = '0' + month;

        return date.getUTCFullYear() + '-' + month + '-' + day;
    }

    handleButtonClick(event) {
        event.preventDefault();
        const serviceId = event.target.dataset.id;

        this.pickupServices.forEach((serviceItem) => {
            if (serviceItem.Id !== serviceId) return;
            serviceItem.isExpanded = !serviceItem.isExpanded;
        });

        this.deliveryServices.forEach((serviceItem) => {
            if (serviceItem.Id !== serviceId) return;
            serviceItem.isExpanded = !serviceItem.isExpanded;
        });
    }

    handleCheckboxChange(event) {
        this.loading = true;
        const serviceId = event.target.value;
        const isChecked = event.target.checked;

        let pickupServices;
        let deliveryServices;

        if (isChecked) {
            pickupServices = this.pickupServices.filter(service => service.Id === serviceId);

            if (pickupServices.length > 0) {
                this.selectedServices.push(pickupServices[0]);
            }
            
            deliveryServices = this.deliveryServices.filter(service => service.Id === serviceId);

            if (deliveryServices.length > 0) {
                this.selectedServices.push(deliveryServices[0]);
            }
        } else {
            this.selectedServices = this.selectedServices.filter(service => service.Id !== serviceId);
        }
        
        this.template.querySelector('c-trip-details').setSelectedServices(this.selectedServices, this.loading);
    }

    async handleLoadRelatedStops() {
        await this.loadAvailableServices(this.selectedLocation);
    }

    showPastTrips(){
        if(this.nwfbSettings.data.TripDispatcherReport__c) {
            const url = '/lightning/page/analytics?wave__assetType=report&wave__assetId=' + this.nwfbSettings.data.TripDispatcherReport__c + '&wave__fv1=' + this.selectedLocation;
            window.open(url, "_blank");
        }
        else{
            const evt = new ShowToastEvent({
                title: 'Warning',
                message: 'There are incomplete settings for displaying the report, please contact your system administrator.',
                variant: 'warning'
            });
            this.dispatchEvent(evt);
        }
    }

    handleLocationOnSave(event){
        event.preventDefault();
        const fields = event.detail.fields;
        fields["Location__c"] = this.selectedLocation;
        this.template.querySelector('lightning-record-form').submit(fields);
    }

    endSpinner(event) {
        // this.loading = event.detail.isLoading;
        setTimeout(() => {
            this.loading = event.detail.isLoading;
        }, 1000);
    }

    get recordTypeIdGeneralDelivery() {
        const recordTypeInfos = this.objectInfo.data.recordTypeInfos;
        return Object.keys(recordTypeInfos).find((rti) => recordTypeInfos[rti].name === 'General Delivery');
    }

    get recordTypeIdGeneralPickup() {
        const recordTypeInfos = this.objectInfo.data.recordTypeInfos;
        return Object.keys(recordTypeInfos).find((rti) => recordTypeInfos[rti].name === 'General Pickup');
    }

    get recordTypeIdDonationPickup() {
        const recordTypeInfos = this.objectInfo.data.recordTypeInfos;
        return Object.keys(recordTypeInfos).find((rti) => recordTypeInfos[rti].name === 'Donation Pickup');
    }
}