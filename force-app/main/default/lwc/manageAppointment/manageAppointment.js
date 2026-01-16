/**
 * Created by dudunato on 06/08/22.
 */

import {api, LightningElement, track} from 'lwc';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class ManageAppointment extends LightningElement {

    loading;

    @api
    timeSlots;

    @api
    appointment;

    @api
    appointmentStatus;

    @api
    editMode;

    @api
    service;

    @track
    appointmentToEdit;

    errorMessage;

    constructor() {
        super();
        this.appointment = {};
        this.appointmentToEdit = {};
        this.editMode = false;
        this.errorMessage = null;
    }

    connectedCallback() {
        this.loading = false;
        this.appointmentToEdit = {...this.appointment};
    }

    get typeOptions() {
        return [
            {
                label: 'Will Call',
                value: 'Will Call',
            },
            {
                label: 'Delivery',
                value: 'Delivery',
            }
        ];
    }

    handleChange(event) {
        let name = event.target.name;
        if (!name) name = event.detail.name;
        this.appointmentToEdit[name] = event.detail.value;
    }

    async handleSave() {
        const allGood = this.validateInputs();
        if (!allGood) return;

        this.loading = true;

        console.log({...this.appointmentToEdit})
        this.appointmentToEdit.ServiceType__c = this.service.SubType__c;

        // error handler not here yet :P
        let newAppointment = {};
        try{
            newAppointment = await saveSObjects({
                sObjects: [this.appointmentToEdit]
            });

        }catch(e){
            console.log('e  ', e);
            this.errorMessage = e.body.pageErrors[0].message;
        }
        
        console.log('newAppointment ', newAppointment );

        let param = {};
        let msg = '';
        let title = '';
        let variant = '';

        if(this.errorMessage !== null){
            msg = this.errorMessage;
            title = 'Error! ';
            variant = 'error';

        }else{
            param = {
                detail: newAppointment[0]
            };

            if (this.appointmentToEdit.Id) {
                msg = 'Appointment Edited!';
            } else {
                msg = 'Appointment Saved!';
            }

            variant = 'success';

            this.dispatchEvent(new CustomEvent('saved', param));
        }

        this.dispatchEvent(new CustomEvent('close'));

        this.dispatchEvent(new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant,
            mode: 'dismissible'
        }));

    }

    handleCancel() {
        this.dispatchEvent(new CustomEvent('close'));
    }

    validateInputs() {
        if (!this.editMode) return true;

        let nRequiredInputs = 0;
        const selectors = 'lightning-input, c-lookup-input, lightning-radio-group, lightning-combobox';
        // const selectors = 'lightning-textarea';
        const inputs = [...this.template.querySelectorAll(selectors)].filter(i => {
            if (i.required) nRequiredInputs++;
            return i.required;
        });

        if (inputs.length === 0) return;

        const validInputs = inputs.reduce((validSoFar, input) => {
            input.reportValidity();
            return validSoFar && input.checkValidity();
        }, true);

        return validInputs && inputs.length === nRequiredInputs;
    }
}