import { LightningElement, track, api } from 'lwc';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';
import listSobjects from '@salesforce/apex/SObjectCRUDController.listSObjects';

export default class SetCallendarEventModal extends LightningElement {    
    @api isModalOpen;

    closeModal(){
        this.passValeuToParent();
        this.isModalOpen = false;
    }

    saveChanges(event){
        //put save logic with framework here
        this.isModalOpen = false;
    }

    handleCancel() {
        console.log('handling cancel');
        closeModel();
    }

    handleSuccess(event) {
        console.log('handling success');
        
        this.saveChanges()
        closeModel();
    }

    passValeuToParent(){
        const event = new CustomEvent('child', {
            detail: {value: false}
        });
        this.dispatchEvent(event);
    }
}