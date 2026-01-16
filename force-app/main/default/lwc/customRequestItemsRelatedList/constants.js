/**
 * Created by Gustavo on 15/06/23.
 */

export const COLUMNS = [
    {
        fieldName: 'recordUrl',
        label: 'Name',
        type: 'url',
        wrapText: true,
        typeAttributes: {label: {fieldName: 'Name'}},
        hideDefaultActions: true,
    },
    {
        type: 'text',
        fieldName: 'Status__c',
        label: 'Status',
        hideDefaultActions: true,
    },
    // {
    //     type: 'number',
    //     fieldName: this.field4,
    //     label: 'Requested',
    //
    // },
    // {
    //     type: 'number',
    //     fieldName: this.field3,
    //     label: 'Provided',
    //     hideDefaultActions: true,
    // },
    {
        type: "button-icon",
        fixedWidth: 40,
        typeAttributes: {
            alternativeText: '',
            class: '',
            iconClass: '',
            iconName: 'utility:add',
            name: 'add',
            title: '',
            variant: 'success'
        }
    },
    {
        type: "button-icon",
        fixedWidth: 40,
        typeAttributes: {
            alternativeText: '',
            class: '',
            iconClass: '',
            iconName: 'utility:dash',
            name: 'subtract',
            title: '',
            variant: 'destructive'
        }
    },
    // {
    //     type: 'number',
    //     fieldName: this.field2,
    //     label: 'Delivered',
    //     hideDefaultActions: true,
    // },
    {
        type: "button-icon",
        fixedWidth: 40,
        typeAttributes: {
            alternativeText: '',
            class: '',
            iconClass: '',
            iconName: 'utility:add',
            name: 'add delivered',
            title: '',
            variant: 'success'
        }
    },
    {
        type: "button-icon",
        fixedWidth: 40,
        typeAttributes: {
            alternativeText: '',
            class: '',
            iconClass: '',
            iconName: 'utility:dash',
            name: 'subtract delivered',
            title: '',
            variant: 'destructive'
        }
    }
];