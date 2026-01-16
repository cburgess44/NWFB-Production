import { LightningElement, api } from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SubmitForDeliveryQuickAction extends LightningElement {
    // api variable
    @api recordId;
    @api invoke(){
        if(this.recordId){
            let fields = {
                Status__c: 'Pending Delivery',
                Id: this.recordId
            }
            const recordInput = { fields }
            updateRecord(recordInput).then(() => {
                this.showToast('Success!', 'The request is now Pending Delivery', 'success');
            }).catch(error => {
                console.log(error);
            });
        }
    }
    
    //show toast method
    showToast(title, message, variant){
        this.dispatchEvent(new ShowToastEvent({
            Title: title,
            message: message,
            variant: variant,
            mode: 'dismissable',
        }));
    }

}