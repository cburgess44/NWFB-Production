/*
 * Created by dudunato on 22/10/22.
 */

export const SERVICES_COLUMNS = [
    {
        type: 'text',
        fieldName: 'customerName',
        label: 'Customer',
    },
    {
        type: 'text',
        fieldName: 'Status__c',
        label: 'Status',
    },
    {
        type: 'text',
        fieldName: 'caseworkerName',
        label: 'Caseworker',
    },
    {
        type: 'date',
        fieldName: 'LastAppointmentDate__c',
        label: 'Last Appointment',
    },
    {
        type: 'text',
        fieldName: 'Accessibility__c',
        label: 'Accessibility',
    },
    {
        type: 'text',
        fieldName: 'area',
        label: 'Area',
    },
    {
        type: 'text',
        fieldName: 'SubType__c',
        label: 'Sub Type',
    },
];

export const PICKUP_ITEM_COLUMNS = [
    {
        type: 'text',
        fieldName: 'name',
        label: 'Name',
    },
    {
        type: 'number',
        fieldName: 'quantity',
        label: 'Quantity',
    },
    {
        type: 'text',
        fieldName: 'type',
        label: 'SubType',
    }
];

export const PICKUP_COLUMNS = [
    {
        type: 'text',
        fieldName: 'customerName',
        label: 'Customer',
    },
    {
        type: 'text',
        fieldName: 'Phone',
        label: 'Phone',
    },
    {
        type: 'date',
        fieldName: 'CreatedDate',
        label: 'Created Date',
    },
    {
        type: 'text',
        fieldName: 'City__c',
        label: 'City',
    },
    {
        type: 'text',
        fieldName: 'Zip__c',
        label: 'Zip Code',
    }
]

export const MOCK_DATA = [
    {
        Id: '001',
        customerName: 'Eric Jones',
        caseworkerName: 'Dudu Nato',
        LastAppointmentDate__c: new Date(),
        Accessibility__c: 'Elevator',
        _children: [
            { customerName: 'Bunk Bed' },
            { customerName: 'Mattress-King' },
            { customerName: 'Furniture' },
        ]
    },
    {
        Id: '002',
        customerName: 'Alissa Oliveira',
        caseworkerName: 'Dudu Nato',
        LastAppointmentDate__c: new Date(),
        Accessibility__c: 'Stairs',
        _children: [
            { customerName: 'Bunk Bed' },
            { customerName: 'Furniture' },
        ]
    },
    {
        Id: '003',
        customerName: 'Guga Santos',
        caseworkerName: 'Dudu Nato',
        LastAppointmentDate__c: new Date(),
        Accessibility__c: 'Ground Level - no stairs',
        _children: [
            { customerName: 'Bunk Bed' },
        ]
    },
    {
        Id: '003',
        customerName: 'Mica Saide',
        caseworkerName: 'Dudu Nato',
        LastAppointmentDate__c: new Date(),
        Accessibility__c: 'Elevator',
        _children: [
            { customerName: 'Bunk Bed' },
            { customerName: 'Mattress-King' },
            { customerName: 'Furniture' },
        ]
    },
];