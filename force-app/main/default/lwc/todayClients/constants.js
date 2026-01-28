/**
 * Created by Gustavo on 27/04/23.
 */
export const REPORT_COLUMNS = [
    {
        label: 'Contact Name',
        fieldName: 'contactName',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Service Name',
        fieldName: 'name',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Sub Type',
        fieldName: 'subType',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Product Name',
        fieldName: 'productName',
        type: 'text',
        hideDefaultActions: true
    },
]

export const APPOINTMENTS_COLUMNS = [
    {
        label: 'Time',
        fieldName: 'serviceUrl',
        type: 'url',
        hideDefaultActions: true,
        typeAttributes: {
            label: {fieldName: 'time'},
            target: '_blank'
        }
    },
    {
        label: 'Contact Name',
        fieldName: 'contactName',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Sub Type',
        fieldName: 'subType',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Service Status',
        fieldName: 'serviceStatus',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Tag Color',
        fieldName: 'tagColor',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Zip Code',
        fieldName: 'zip',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Client Service Review',
        initialWidth: 160,
        type: 'button',
        typeAttributes: {
            name: 'appointmentButton',
            disabled: { fieldName: 'appointmentAlreadyReviewed'},
            label: 'Mark Reviewed',
            class: {fieldName: 'markReviewButtonClass'}
        },
        hideDefaultActions: true
    },
]

export const TRIPS_COLUMNS = [
    {
        label: 'Trip Name',
        fieldName: 'tripUrl',
        type: 'url',
        hideDefaultActions: true,
        typeAttributes: {
            label: {fieldName: 'name'},
            target: '_blank'
        }
    },
    {
        label: 'Primary Timeframe',
        fieldName: 'primaryTimeframe',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Driver',
        fieldName: 'driverName',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Copilot',
        fieldName: 'copilotName',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Stop Count',
        fieldName: 'stopCount',
        type: 'text',
        hideDefaultActions: true
    },
    {
        label: 'Area',
        fieldName: 'locationCity',
        type: 'text',
        hideDefaultActions: true
    },
]