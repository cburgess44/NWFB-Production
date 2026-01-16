import { LightningElement, api } from 'lwc';
import listSObjects from '@salesforce/apex/SObjectCRUDController.listSObjects';

export default class InvokeInvoicePaymentFromInvoice extends LightningElement {
    @api recordId;
    invoiceId;
    agencyId;
    showInvCmp;
  
    async connectedCallback(){
      
  }
  
  @api async invoke() {
    
    window.open('/apex/InvoicePDF?recordId='+this.recordId+'&invoiceId='+invoiceId, '_blank')
  }

}