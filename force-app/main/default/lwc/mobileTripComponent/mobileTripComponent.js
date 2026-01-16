import { LightningElement, api, wire, track } from 'lwc';
import { getRecord,getFieldValue } from 'lightning/uiRecordApi';
const WEEKDAY = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
const MONTH = ["January","February","March","April","May","June","July","August","September","October","November","December"];
export default class MobileTripComponent extends LightningElement {
    
    @api recordId;
    @track options = [
        { label: 'Chair', value: 'option1' },
        { label: 'Table', value: 'option2' },
        { label: 'Bed', value: 'option3' },
    ];
    openMap = false;
    value = ['option1'];

    get buttonLabel(){
        return (this.openMap ? 'Stop Trip navigation' : 'Start Trip navigation')
    }
    //get record info to set title and location names
    @wire(getRecord, { recordId: '$recordId', fields: ['Trip__c.Location__r.Name', 'Trip__c.Date__c'] })
    record({ error, data }) {
        if (data) {
            this.error = undefined;
            //set location name
            this.locationName = getFieldValue(data, 'Trip__c.Location__r.Name');

            //set title date
            let date = new Date(getFieldValue(data, 'Trip__c.Date__c'));
            this.title = WEEKDAY[date.getDay()] + ', ' + MONTH[date.getMonth()] + ' ' + date.getDate() + 'th' 
        } else if (error) {
            this.error = error;
            this.isLoaded = true;
        }
    }
    handleClickStartNavigation(){
        this.openMap = !this.openMap;
    }
    handleChangeCheckboxGroup(){

    }
}