/**
 * Created by Gustavo on 13/02/25.
 */

import {api, LightningElement, track} from 'lwc';

export default class DonorGivingStatementsButton extends LightningElement {


    @track
    enableModal;

    @api
    recordId

    @track
    settings;

    constructor() {
        super();
        this.settings = {};
    }

    handleOpenModal() {
        this.enableModal = true;
    }

    handleCloseModal() {
        this.enableModal = false;
    }

    handleOpenPDF() {
        window.open('/apex/DonorGivingStatements?id=' + this.recordId + '&from=' + this.settings.fromDate + '&to=' + this.settings.toDate);
    }

    handleChangeInput(event) {
       this.settings[event.target.name] = event.target.value;
    }

    get disableOpenButton() {
        return !this.settings.fromDate || !this.settings.toDate;
    }

}