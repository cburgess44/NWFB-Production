import { LightningElement, api } from 'lwc';
import saveSObjects from '@salesforce/apex/SObjectCRUDController.saveSObjects';
import listSObjects from '@salesforce/apex/SObjectCRUDController.listSObjects';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import { NavigationMixin } from 'lightning/navigation';

export default class MarkAsReplyButton extends NavigationMixin(LightningElement)  {

    task;
    message = '';
    loading = false;

    @api recordId;
    @api sObjectName;
    
    constructor(){
        super();
    }

    async connectedCallback() {
        await this.getTask();
        await this.markTaskAsRead();
    }

    async markTaskAsRead() {
        const taskToUpdate  = {
            sobjectType: 'Task',
            Id: this.recordId,
            Read__c: true,
        };

        let msg = '';
        let title = '';
        let variant = '';

        try {
            const result = await saveSObjects({sObjects: [taskToUpdate]});

            // if (result === null || result.length === 0){
            //     msg = 'Something went wrong! Contact your administrator...';
            //     title = 'Error!';
            //     variant = 'error';
            //
            // }else{
            //     msg = 'SMS changed to Reply!';
            //     title = 'Success!';
            //     variant = 'success';
            // }
            //
            // this.dispatchEvent(
            //     new ShowToastEvent( {
            //         title: title,
            //         message: msg,
            //         variant: variant,
            //         mode: 'pester'
            //     } )
            // )
        } catch (e) {
            console.error('Error: ', e);
        }
    }

    async getTask() {
        try {
            const tasks = await listSObjects({
                objectName: 'Task',
                fields: [
                    'WhoId',
                    'WhatId',
                    'MobilePhone__c'
                ],
                filters: `AND Id = '${this.recordId}'`
            });

            if (tasks.length === 0) return;

            this.task = tasks[0];
        } catch (e) {
           console.error('Error: ', e);
        }
    }

    handleChangeMessageInput(event) {
        this.message = event.target.value;
    }

    handleCloseModal() {
        const close = new CustomEvent('close');
        this.dispatchEvent(close);
    }

    async handleReplyMessage() {
        try {
            this.loading = true;
            const replyTaskMessage = {
                sobjectType: 'Task',
                MessageType__c: 'Outgoing',
                Status: 'Completed',
                Subject: 'Reply SMS',
                WhatId: this.task.WhatId,
                Type: 'SMS',
                MobilePhone__c: this.task.MobilePhone__c,
                WhoId: this.task.WhoId,
                Description: this.message,
                CompletedDateTime: new Date()
            };

            await saveSObjects({sObjects: [replyTaskMessage]});

            this.dispatchEvent(
                new ShowToastEvent( {
                    title: 'Message Replied Successfully',
                    variant: 'success',
                })
            );
            this.handleCloseModal();
        } catch (e) {
            console.error('Error: ', e);
            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message: e,
                variant: 'error',
            }));
            this.loading = false;
        }
    }
}