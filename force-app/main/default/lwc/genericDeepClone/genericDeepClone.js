import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import fullClone from "@salesforce/apex/SObjectDeepCloneController.fullClone";


export default class GenericDeepClone extends NavigationMixin(LightningElement) {
    isExecuting = false;
    @api objectApiName;
    @api childrenRelationships = [];
    @api fieldsValue = '';
    @api recordId;
    @api async invoke() {
        if (this.isExecuting) {
            return;
        }

        this.isExecuting = true;
        await this.clone();
        this.isExecuting = false;
    }
    clone() {
        return new Promise((resolve) => fullClone({
            recordId: this.recordId,
            childrenRelationships: this.childrenRelationships,
            fieldsValue: this.fieldsValue
          })
          .then((recordId) => {
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Success!",
                  message: "The record was cloned successfully!",
                  variant: "success",
                  mode: "dismissable"
                })
              );
              this.navigateToNewRecordpage(recordId)
            })
            .catch((err) => {
              console.log(err);
              this.dispatchEvent(
                new ShowToastEvent({
                  title: "Error!",
                  message: "The record was no cloned",
                  variant: "error",
                  mode: "dismissable"
                })
              );
            }));
    }

    navigateToNewRecordpage(recordId){
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                objectApiName: this.objectApiName,
                actionName: 'view',
                recordId: recordId
            },
        });
    }
}