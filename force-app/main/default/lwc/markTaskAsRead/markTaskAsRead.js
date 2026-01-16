/**
 * Created by Gustavo on 16/10/23.
 */

import {api, LightningElement, track} from 'lwc';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {CloseActionScreenEvent} from "lightning/actions";

export default class MarkTaskAsRead extends LightningElement {

    @track
    loading = false;

    @api
    recordId;

    async connectedCallback() {
        this.loading = true;
        await this.markTaskAsRead();
    }

    async markTaskAsRead() {
        try {
            this.loading = true;

            const task = {
                Id: this.recordId,
                Read__c: true
            };

            await saveSObjects({
                sObjects: [task]
            });

            this.dispatchEvent(
                new ShowToastEvent( {
                    title: 'Success',
                    message: 'Message marked as read',
                    variant: 'success',
                })
            )

            window.location.reload();
        } catch (e) {
            console.error('Error: ', e);
            this.loading = false;
        }


    }

}