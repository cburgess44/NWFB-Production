import { LightningElement,api } from 'lwc';

export default class PickupDeepClone extends LightningElement {
  @api recordId;
  @api async invoke() {
    this.template.querySelector('c-generic-deep-clone').invoke()
  }
}