import { LightningElement,api } from 'lwc';

export default class PickupDeepClone extends LightningElement {
  @api recordId;
  @api async invoke() {
    window.open('/apex/InvoicePDF?id='+this.recordId, '_blank')
  }
}