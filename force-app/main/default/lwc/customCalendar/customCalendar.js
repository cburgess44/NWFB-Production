/**
 * Created by dudunato on 01/08/22.
 */

import {api, LightningElement, track} from 'lwc';

import FullCalendarResource from '@salesforce/resourceUrl/FullCalendar';
import {loadScript, loadStyle} from 'lightning/platformResourceLoader';
import listSobjects from '@salesforce/apex/SObjectCRUDController.listSObjects';
import getPicklist from '@salesforce/apex/SObjectCRUDController.getPicklist';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

import {getDates, normalizePosition} from './helper';
import {dates} from 'c/generalUtilities'

export default class CustomCalendar extends LightningElement {

    @api
    recordId;

    @track
    events;

    @track
    managingAppointment;

    @track
    appointmentToManage;

    calendar;
    firstLoaded;
    appointments;
    appointmentExceptions;
    statusPicklistValues;
    timePicklistValues;
    cachedEvent;
    request;
    loading;

    constructor() {
        super();
        this.firstLoaded = false;
        this.managingAppointment = false;
        this.loading = false;
        this.events = [];
        this.appointments = [];
        this.statusPicklistValues = [];
        this.timePicklistValues = [];
        this.appointmentExceptions = [];
    }

    async connectedCallback() {
        await this.init();
    }

    async init() {
        await this.getTimePickListValues();
        await this.getStatusPickListValues();

        this.template.addEventListener('click', (e) => {
            if (!e.target || !e.target.offsetParent || !e.target.offsetParent.classList) return;

            // hide context menu when clicked outside
            const contextMenu = this.template.querySelector('.context-menu');
            if (!e.target.offsetParent.classList.contains('fc-content') && !e.target.offsetParent.classList.contains('context-menu')) {
                contextMenu.classList.remove('visible');
            }
        });
    }

    async renderedCallback() {

        if (this.firstLoaded) return;
        this.firstLoaded = true;

        await loadScript(this, FullCalendarResource + '/packages/core/main.js');
        await loadStyle(this, FullCalendarResource + '/packages/core/main.css');

        await loadScript(this, FullCalendarResource + '/packages/daygrid/main.js');
        await loadStyle(this, FullCalendarResource + '/packages/daygrid/main.css');

        await loadScript(this, FullCalendarResource + '/packages/list/main.js');
        await loadStyle(this, FullCalendarResource + '/packages/list/main.css');

        await loadScript(this, FullCalendarResource + '/packages/timegrid/main.js');
        await loadStyle(this, FullCalendarResource + '/packages/timegrid/main.css');

        await loadScript(this, FullCalendarResource + '/packages/interaction/main.js');

        await loadScript(this, FullCalendarResource + '/packages/moment/main.js');
        await loadScript(this, FullCalendarResource + '/packages/moment-timezone/main.js');


        this.initFullCalendarResource();
    }

    initFullCalendarResource() {
        const calendarEl = this.template.querySelector('.calendar');

        this.calendar = new FullCalendar.Calendar(calendarEl, {
            header: {
                left: 'title',
                center: '',
                right: 'prev,next today,timeGridWeek,timeGridDay,dayGridMonth'
            },

            plugins: ['dayGrid', 'timeGrid', 'list', 'interaction', 'moment'],

            defaultView: 'timeGridWeek',

            minTime: "09:15:00",
            maxTime: "17:00:00",
            hiddenDays: [0],

            height: 'auto',
        
            views: {
                listDay: {buttonText: 'list day'},
                listWeek: {buttonText: 'list week'},
                listMonth: {buttonText: 'list month'},
                timeGridWeek: {buttonText: 'week'},
                timeGridDay: {buttonText: 'day'},
                dayGridMonth: {buttonText: 'month'},
                dayGridWeek: {buttonText: 'week'},
                dayGridDay: {buttonText: 'day'}
            },

            events: async (info, successCallback, failureCallback) => {
                await this.calendarRenderer(info, successCallback, failureCallback);
            },

            eventTimeFormat: {
                hour: '2-digit',
                minute: '2-digit',
                meridiem: true
            },

            eventClick: (info) => {
                this.handleEventClick(info);
            },
        });

        this.calendar.render();
    }

    async calendarRenderer(info, success, failure) {

        try {
            this.loading = true;

            await this.getRequest();
            await this.getAppointmentExceptions(info.start, info.end);
            await this.getAppointments(info.start, info.end);
            await this.getEvents(info.start, info.end);
            success(this.events);

            this.loading = false;
        } catch (e) {
            failure(e);
        }
    }

    closeModal() {
        this.managingAppointment = false;
    }

    async getEvents(firstWeekDay, lastWeekDay) {
        let events = [];
        const filledSlots = {};
        for (let record of this.appointments) {
            filledSlots[record.Date__c + record.Time__c] = true;

            const {start, end} = getDates(record.Date__c, record.Time__c);

            const event = {
                id: record.Id,
                title: record.Service__c? record.Service__r.Contact__c? record.Service__r.Contact__r.Name: 'No client Name ' : 'No client Name ',
                start: start,
                end: end,
                allDay: false,
                color: this.setEventColor(record.ServiceType__c),
                overlap: true,
                display: 'auto',
                extendedProps: record,
                borderColor: '#000000',
                // borderWidth: '10px'
            };

            events.push(event);
        }

        for (let exception of this.appointmentExceptions) {
            const slots = exception.TimeSlots__c.split(';');

            for (let slot of slots) {
                if (filledSlots[exception.Date__c + slot]) continue;

                const {start, end} = getDates(exception.Date__c, slot);

                const props = exception.Type__c === 'Available'
                    ? {
                        Date__c: exception.Date__c,
                        Time__c: slot
                    } : {
                        blocked: true
                    };

                events.push({
                    id: exception.Type__c.toLowerCase() + exception.Date__c + slot,
                    title: exception.Type__c,
                    start: start,
                    end: end,
                    color: this.setEventColor(exception.Type__c),
                    display: 'auto',
                    extendedProps: props,
                    borderColor: '#000000',
                });

                filledSlots[exception.Date__c + slot] = true;
            }
        }

        for (let d = firstWeekDay; d <= lastWeekDay; d.setDate(d.getDate() + 1)) {
            // if Sun or Mon skip
            if (d.getDay() === 0 || d.getDay() === 1) continue;

            const currentSFDate = dates.sfDate(d);

            for (let timeSlot of this.timePicklistValues) {
                if (filledSlots[currentSFDate + timeSlot.value]) continue;

                const {start, end} = getDates(currentSFDate, timeSlot.value);
                events.push({
                    id: currentSFDate + timeSlot.value,
                    title: 'Available',
                    start: start,
                    end: end,
                    color: this.setEventColor('available'),
                    display: 'auto',
                    extendedProps: {
                        Date__c: currentSFDate,
                        Time__c: timeSlot.value
                    },
                });
            }

        }

        this.events = events;
    }

    async getAppointments(firstWeekDay, lastWeekDay) {
        try {
            let filter = (
                `AND Status__c != 'Cancelled' AND Status__c != 'Rescheduled' ` +
                `AND Date__c != NULL AND Time__c != NULL ` + // just to filter out junk data
                `AND (Date__c >= ${dates.sfDate(firstWeekDay)} OR Date__c <= ${dates.sfDate(lastWeekDay)}) `
            );

            if (this.request.Location__c) filter += `AND Service__r.Location__c = '${this.request.Location__c}' `;

            const appointments = await listSobjects({
                objectName: 'Appointment__c',
                fields: [
                    'Name',
                    'Service__c',
                    'Date__c',
                    'DisplayName__c',
                    'TagColor__c',
                    'Time__c',
                    'ServiceType__c',
                    'Notes__c',
                    'Service__r.Contact__r.Name',
                ],
                filters: filter
            });

            if (appointments === null) return;

            this.appointments = appointments;
        } catch (e) {
            console.error('Error: ', e);
        }

    }

    async getRequest() {
        try {
            const filter = `AND Id = '${this.recordId}' `;

            const request = await listSobjects({
                objectName: 'Service__c',
                fields: [
                    'Id',
                    'Name',
                    'Location__c',
                    'Status__c',
                    'Contact__r.Name',
                    'Contact__r.Email',
                    'Pickup_type__c',
                    'SubType__c'
                ],
                filters: filter
            });

            if (request === null) return;

            this.request = request[0];
        } catch (e) {
            console.error('Error: ', e);
        }

    }

    async getAppointmentExceptions(firstWeekDay, lastWeekDay) {
        try {
            const filter = (
                `AND (Date__c >= ${dates.sfDate(firstWeekDay)} OR Date__c <= ${dates.sfDate(lastWeekDay)})` +
                'AND Location__c = ' + "'" + this.request.Location__c + "'"
            );

            const exceptions = await listSobjects({
                objectName: 'AppointmentException__c',
                fields: [
                    'Name',
                    'Date__c',
                    'Type__c',
                    'TimeSlots__c',
                ],
                filters: filter
            });

            if (exceptions === null) return;

            this.appointmentExceptions = exceptions;
        }  catch (e) {
            console.error('Error: ', e);
        }
    }

    async getStatusPickListValues() {
        try {
            const statusPicklistValues = await getPicklist({
                objectName: 'Appointment__c',
                fieldName: 'Status__c'

            });

            if (statusPicklistValues === null) return;

            this.statusPicklistValues = statusPicklistValues;
        } catch (e) {
            console.error('Error: ', e);
        }
    }

    async getTimePickListValues() {
        try {
            const timePicklistValues = await getPicklist({
                objectName: 'Appointment__c',
                fieldName: 'Time__c'

            });

            if (timePicklistValues === null) return;

            this.timePicklistValues = timePicklistValues;
        } catch (e) {
            console.error('Error: ', e);
        }
    }

    setEventColor(type) {

        type = type != null && type != 'undefined' ? type.toLowerCase() : 'undefined';

        const eventColors = {
            willcall: '#0000FF',
            delivery: '#F5581D',
            available: '#89D3A8',
            block: '#7E7E7E',
            undefined: '#FA76CA',
            cancelled: '#808080',
        };

        return eventColors[type];
    }

    async handleEventClick(info) {
        if (info.event.extendedProps.blocked) return;

        this.cachedEvent = info.event;

        if (this.cachedEvent.extendedProps.Id) {
            this.showContextMenu(info);
            return;
        }

        try {
            await this.handleContextMenuAction(null, 'new');
        } catch (e) {
            console.error('Error: ', e);
        }

    }

    showContextMenu(info) {
        const contextMenu = this.template.querySelector('.context-menu');
        const scope = this.template.querySelector('.calendar');

        const {clientX: mouseX, clientY: mouseY} = info.jsEvent;

        const {normalizedX, normalizedY} = normalizePosition(scope, contextMenu, mouseX, mouseY);

        contextMenu.classList.remove('visible');
        contextMenu.style.top = `${normalizedY}px`;
        contextMenu.style.left = `${normalizedX}px`;
        contextMenu.classList.add('visible');
    }

    async handleContextMenuAction(event, action) {
        const currentAction = action ? action : event.currentTarget.dataset.action;
        this.loading = true;
        switch (currentAction) {
            case 'new':
                this.appointmentToManage = {
                    sobjectType: 'Appointment__c',
                    Service__c: this.recordId,
                    Date__c: this.cachedEvent.extendedProps.Date__c,
                    Time__c: this.cachedEvent.extendedProps.Time__c,
                    ContactEmail__c: this.request.Contact__r.Email,
                    ServiceType__c: this.request.Pickup_type__c,
                };
                this.managingAppointment = true;
                break;

            case 'noshow':
                await this.updateAppointmentStatus('No Show');
                await this.init();
                break;
            case 'rescheduled':
                await this.updateAppointmentStatus('Rescheduled');
                await this.init();
                break;
            case 'delete':
                await this.deleteAppointment();
                await this.init();
                break;
        }
        this.loading = false;
        this.template.querySelector('.context-menu').classList.remove('visible');
    }

    async updateAppointmentStatus(status) {
        try {
            this.loading = true;
            const appointment ={
                sobjectType: 'Appointment__c',
                Id: this.cachedEvent.extendedProps.Id,
                Status__c: status,

            };

            await saveSObjects({sObjects: [appointment]});

            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message: 'Appointment Status Updated Successfully!',
                variant: 'success',
                mode: 'dismissible'
            }));

            this.loading = false;
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }
    }

    async deleteAppointment() {
        const recordsToUpdate = [];

        const appointment ={
            sobjectType: 'Appointment__c',
            Id: this.cachedEvent.extendedProps.Id,
            Status__c: 'Cancelled',
        };

        recordsToUpdate.push(appointment);

        const request = {
            sobjectType: 'Service__c',
            Id: this.cachedEvent.extendedProps.Service__c,
            Status__c: 'Processing',
        };

        recordsToUpdate.push(request);

        const result = await saveSObjects({
            sObjects: recordsToUpdate
        });

        if (result === null || result.length === 0) throw new Error(`it wasn't possible to update Appointment and Request`);

        this.calendar.getEventById(appointment.Id).remove();
        this.calendar.refetchEvents();

        this.dispatchEvent(new ShowToastEvent({
            title: '',
            message: 'Appointment Canceled!',
            variant: 'success',
            mode: 'dismissible'
        }));

        // window.location.reload();
    }

    async handleNewAppointment(event) {
        this.managingAppointment = false;

        const newAppointment = event.detail;

        // const dateString = sfDate(new Date(newAppointment.Date__c));
        //
        // const {start, end} = getDates(dateString, newAppointment.Time__c);

        // const newEvent = {
        //     id: newAppointment.Id,
        //     title: newAppointment.Name,
        //     start: start,
        //     end: end,
        //     allDay: false,
        //     color: this.setEventColor(newAppointment.Type__c),
        //     overlap: true,
        //     display: 'auto',
        //     extendedProps: newAppointment,
        //     borderColor: '#000000'
        // };

        // let calendarEvent = this.calendar.getEventById(dateString + newAppointment.Time__c);
        //
        // if (!calendarEvent) calendarEvent = this.calendar.getEventById(newAppointment.Id);
        //
        // if (calendarEvent) calendarEvent.remove();

        // this.calendar.addEvent(newEvent);

        let request = null;
        if(this.request.Status__c === 'Pending Scheduling'){
            request  = {
                sobjectType: 'Service__c',
                Id: newAppointment.Service__c,
                Status__c: 'Scheduled',
            };
        }

        if (request !== null) {
            await saveSObjects({
                sObjects: [request]
            });
        }

        this.calendar.refetchEvents();
        await this.init();
        // window.location.reload();
    }


}