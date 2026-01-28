/**
 * Created by Gustavo on 14/04/23.
 */

import {api, LightningElement, track, wire} from 'lwc';
import {getSfDate} from 'c/utils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import listSObjects from '@salesforce/apex/SObjectCRUDController.listSObjects';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';
import userId from '@salesforce/user/Id';
import {APPOINTMENTS_COLUMNS, REPORT_COLUMNS, TRIPS_COLUMNS} from './constants';
import getCustomSettings from '@salesforce/apex/SObjectCRUDController.getCustomSettings';
import ExtraOfficePermission from '@salesforce/customPermission/ExtraOfficePermissions';
import ExtraDriverPermission from '@salesforce/customPermission/ExtraDriverPermissions';


export default class TodayClients extends LightningElement {

    @track
    bedReportData;

    @track
    clientDate = null;

    @track
    enableTodayBedReport = false;

    @track
    appointmentsFiltered = [];

    @track
    tripsFiltered = [];

    @track
    locationsOptions = null;

    @track
    appointmentsFilteredByContactNameAndSubType = null;

    @track
    loading = false;

    @track
    disableBedReportButton = false

    @track
    serviceItems = [];

    @track
    locationValue = null;

    availableProfiles = [];
    trips = [];
    appointments = [];
    enableTripsTab = false;
    reportColumns = [];
    appointmentsColumns = [];
    tripsColumns = [];

    @wire(getCustomSettings)
    nwfbSettings;

    async connectedCallback() {
        await this.init();
    }

    async init() {
        console.log('init');
        this.loading = true;
        this.disableBedReportButton = true;
        this.reportColumns = REPORT_COLUMNS;
        this.tripsColumns = TRIPS_COLUMNS;
        this.appointmentsColumns = APPOINTMENTS_COLUMNS;
        this.availableProfiles = [
            'NWFB Platform Standard',
            'System Administrator',
        ];
        this.clientDate = getSfDate(new Date());
        await this.loadAppointments();

        if (this.appointmentsFiltered.length > 0) {
            this.disableBedReportButton = false;
            await this.loadBedroomServiceItems();
            this.enableTodayBedReport = true;
        }

        await this.loadTrips();
        await this.loadLocations();
        await this.loadLoggedUser();
        await this.loadLoggedUserLocation();
        this.enableTripsTab = this.availableProfiles.includes(this.loggedUser?.Profile?.Name) || ExtraDriverPermission;
        this.loading = false;
    }

    async loadLoggedUserLocation() {
        const loggedUserLocation = await listSObjects({
            objectName: 'User_Location__c',
            fields: ['Id', 'Location__c'],
            filters: `AND User__c = '${this.loggedUser.Id}' AND main__c = TRUE`
        });

        if (loggedUserLocation.length === 0) return;

        this.appointmentsFiltered = this.appointments.filter((appointment) => appointment.location === loggedUserLocation[0].Location__c);
        this.tripsFiltered = this.trips.filter((trip) => trip.location === loggedUserLocation[0].Location__c);

        this.locationValue = loggedUserLocation[0].Location__c;
    }

    async loadLoggedUser() {
        const user = await listSObjects({
            objectName: 'User',
            fields: ['Id', 'Profile.Name'],
            filters: `AND Id = '${userId}'`
        });

        if (user.length === 0) return;

        this.loggedUser = user[0];
    }

    async loadLocations() {
        try {
            const locations = await listSObjects({
                objectName: 'Location__c',
                fields: [
                    'Id',
                    'Name',
                    'City__c',
                ],
                filters: `AND Active__c = TRUE`
            });

            if (locations.length === 0) return;

            this.locationsOptions = locations.map((location) => {
                return {
                    label: location.City__c,
                    value: location.Id
                }
            });

            this.locationsOptions.push({
                label: 'None Selected',
                value: ''
            });
        } catch (e) {
            console.error('Error: ', e);
        }
    }

    async loadAppointments() {
        console.log('Extra Office => ' + ExtraOfficePermission);
        try {
            const appointments = await listSObjects({
                objectName: 'Appointment__c',
                fields: [
                    'Id',
                    'Status__c',
                    'Service__c',
                    'Service__r.Contact__r.Name',
                    'Service__r.ClientServicesReviewed__c',
                    'Service__r.Status__c',
                    'Service__r.Location__c',
                    'Service__r.Tag_Color__c',
                    'Service__r.Zip__c',
                    'ServiceType__c',
                    'Time__c',
                    'Service__r.SubType__c',
                    'Service__r.Total_Items__c',
                ],
                filters: `AND Date__c = ${this.clientDate} AND Status__c = 'Scheduled' ORDER BY Time__c`
            });
            if (appointments.length === 0) {
                this.appointmentsFiltered = [];
                this.appointments = [];
                return;
            }

            this.appointments = appointments.map((appointment) => {
                return {
                    id: appointment.Id,
                    serviceUrl: '/lightning/r/Service__c/' + appointment.Service__c + '/view',
                    contactName: appointment.Service__r.Contact__r.Name,
                    subType: appointment.ServiceType__c,
                    status: appointment.Status__c,
                    serviceId: appointment.Service__c,
                    serviceStatus: appointment.Service__r?.Status__c,
                    tagColor: appointment.Service__r.Tag_Color__c,
                    zip: appointment.Service__r?.Zip__c,
                    location: appointment.Service__r?.Location__c,
                    time: appointment.Time__c,
                    serviceTotalItems: appointment.Service__r?.Total_Items__c,
                    appointmentAlreadyReviewed: !!appointment.Service__r?.ClientServicesReviewed__c,
                    markReviewButtonClass: !ExtraOfficePermission ? 'slds-hide' : ''
                }
            });

            if (this.locationValue !== null) {
                this.appointmentsFiltered = this.appointments.filter((appointment) => appointment.location === this.locationValue);
            } else {
                this.appointmentsFiltered = this.appointments;
            }

        } catch (e) {
            console.error('Error: ', e);
        }
    }

    async loadTrips() {
        try {
            let trips = await listSObjects({
                objectName: 'Trip__c',
                fields: [
                    'Id',
                    'Name',
                    'Date__c',
                    'Driver__r.Name',
                    'CoPilot1__r.Name',
                    'Contact__r.Name',
                    'Location__r.Name',
                    'PrimaryTimeframe__c',
                    'Location__c',
                    'Location__r.City__c',
                    'Service__r.Total_Items__c',
                    'Service__r.SubType__c',
                    'TotalStopTime__c',
                    'Stop_Count__c'
                ],
                filters: `AND Date__c = ${this.clientDate} ORDER BY PrimaryTimeframe__c`
            });

            if (trips.length === 0) {
                this.tripsFiltered = [];
                this.trips = [];
                return
            }

            trips.sort((a, b) => {
                if (a.PrimaryTimeframe__c === 'morning' && b.PrimaryTimeframe__c === 'afternoon') {
                    return -1;
                } else if (a.PrimaryTimeframe__c === 'afternoon' && b.PrimaryTimeframe__c === 'morning') {
                    return 1;
                } else {
                    return 0;
                }
            });

            this.trips = trips.map((trip) => {
                return {
                    id: trip.Id,
                    name: trip.Name,
                    date: trip.Date__c,
                    tripUrl: '/lightning/r/Trip__c/' + trip.Id + '/view',
                    driverName: trip.Driver__r?.Name,
                    copilotName: trip.CoPilot1__r?.Name,
                    totalStopTime: trip.TotalStopTime__c,
                    stopCount: trip.Stop_Count__c,
                    contactName: trip.Contact__r?.Name,
                    primaryTimeframe: trip.PrimaryTimeframe__c,
                    locationCity: trip.Location__r?.City__c,
                    location: trip.Location__c,
                    serviceTotalItems: trip.Service__r?.Total_Items__c,
                    subType: trip.Service__r?.SubType__c
                }
            });

            if (this.locationValue !== null) {
                this.tripsFiltered = this.trips.filter((trip) => trip.location === this.locationValue);
            } else {
                this.tripsFiltered = this.trips;
            }

        } catch (e) {
            console.error('Error: ', e);
        }
    }

    async loadBedroomServiceItems() {
        const servicesIds = this.appointmentsFiltered?.map((appointment) => appointment.serviceId).join('\',\'');

        if (!servicesIds) return;

        let serviceItems = await listSObjects({
            objectName: 'ServiceItem__c',
            fields: [
                'Id',
                'Name',
                'Service__c',
                'Service__r.Name',
                'Service__r.Total_Items__c',
                'Service__r.Contact__r.Name',
                'Service__r.SubType__c',
                'Product__r.Name',
                'Product__r.Id',
                'Product__r.Category__c'
            ],
            filters: `AND Service__c IN ('${servicesIds}') AND Product__r.Category__c = 'Bedroom'`
        });

        if (serviceItems.length === 0) {
            this.disableBedReportButton = true;
            this.enableTodayBedReport = false;
            return;
        }

        this.serviceItems = serviceItems.map((serviceItem) => {
            return {
                name: serviceItem.Name,
                id: serviceItem.Id,
                serviceContactName: serviceItem.Service__r?.Contact__r?.Name,
                serviceId: serviceItem.Service__c,
                serviceName: serviceItem.Service__r?.Name,
                serviceTotalItems: serviceItem.Service__r?.Total_Items__c,
                serviceSubType: serviceItem.Service__r?.SubType__c,
                productName: serviceItem.Product__r?.Name,
                productId: serviceItem.Product__r?.Id,
                productCategory: serviceItem.Product__r?.Category__c
            }
        });

        this.disableBedReportButton = false;
    }

    async saveService(service) {
        await saveSObjects({sObjects: [service]});
    }

    async handleDateChange(event) {
        this.loading = true;
        this.clientDate = event.target.value;
        this.enableTodayBedReport = false;
        this.disableBedReportButton = true;

        await this.loadAppointments();
        await this.loadTrips();

        if (this.appointmentsFiltered.length > 0) {
            await this.loadBedroomServiceItems();
        }

        this.loading = false;
    }

    async handleClickDaysButton(event) {
        this.loading = true;
        this.enableTodayBedReport = false;
        this.disableBedReportButton = true;

        const eventName = event.target.dataset.name;
        const clientDate = new Date(this.clientDate);

        if (eventName === 'previous') clientDate.setDate(clientDate.getDate());
        else if (eventName === 'next') clientDate.setDate(clientDate.getDate() + 2);

        this.clientDate = getSfDate(clientDate);

        await this.loadAppointments();
        await this.loadTrips();

        if (this.appointmentsFiltered.length > 0) {
            await this.loadBedroomServiceItems();
        }

        this.loading = false;
    }

    async handleClickClientServiceReview(event) {
        if (event.detail.action.name !== 'appointmentButton') return;
        this.loading = true;

        const serviceId = event.detail.row.serviceId;
        const appointmentId = event.detail.row.id;

        this.appointments.find((appointment) => appointment.id === appointmentId).appointmentAlreadyReviewed = true;
        this.appointmentsFiltered.find((appointment) => appointment.id === appointmentId).appointmentAlreadyReviewed = true;

        const service = {
            Id: serviceId,
            ClientServicesReviewed__c: this.clientDate,
            sobjectType: 'Service__c'
        }

        this.appointmentsFiltered = [...this.appointmentsFiltered];
        await this.saveService(service);
        this.loading = false;
    }

    handleChangeLocation(event) {
        this.loading = true;
        this.enableTodayBedReport = false;
        this.disableBedReportButton = true;
        this.appointmentsFiltered = this.appointments;
        this.tripsFiltered = this.trips;

        if (!event.detail.value) {
            this.loading = false;
            return;
        }

        this.appointmentsFiltered = this.appointments.filter((appointment) => appointment.location === event.detail.value);
        this.tripsFiltered = this.trips.filter((trip) => trip.location === event.detail.value);
        this.locationValue = event.detail.value;
        this.loading = false;
    }

    handleClickReportButton() {
        this.loading = true;
        this.enableTodayBedReport = !this.enableTodayBedReport;

        if (!this.enableTodayBedReport) {
            this.loading = false;
            return;
        }

        const bedReportData = this.serviceItems.reduce((acc, currentServiceItem) => {
            return {
                ...acc,
                [currentServiceItem.serviceId]: {
                    id: currentServiceItem.serviceId,
                    name: currentServiceItem.serviceName,
                    contactName: currentServiceItem.serviceContactName,
                    productName: currentServiceItem.productName,
                    productId: currentServiceItem.productId,
                    subType: currentServiceItem.serviceSubType,
                }
            }
        }, {});

        this.bedReportData = Object.values(bedReportData);
        this.loading = false;
    }

    handleClickSFReportButton(){

        if (this.nwfbSettings.data.TodaysTripReport__c != null){
            let url = `/lightning/page/analytics?wave__assetType=report&wave__assetId=${this.nwfbSettings.data.TodaysTripReport__c}&wave__fv0=${this.clientDate}`;
            if (this.locationValue) url + '&wave__fv1=' + this.locationValue;
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

    get showAppointmentErrorMessage() {
        return this.loading === false && (this.appointmentsFiltered.length === 0 || !this.appointmentsFiltered);
    }

    get showTripsErrorMessage() {
        return this.loading === false && (this.tripsFiltered.length === 0 || !this.tripsFiltered);
    }
}