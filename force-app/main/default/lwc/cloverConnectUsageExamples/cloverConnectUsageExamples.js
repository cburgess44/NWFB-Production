/**
 * Created by dudunato on 15/06/22.
 */

import {LightningElement} from 'lwc';
import {
    simpleForm,
    formWithAllOptions,
    manageAccounts,
    formWithSavedAccounts,
    lockedAmountForm,
} from './codeExamples';

export default class CloverConnectUsageExamples extends LightningElement {

    codeExamples =  {
        simpleForm,
        formWithAllOptions,
        manageAccounts,
        formWithSavedAccounts,
        lockedAmountForm,
    };

    userFieldsExample = {
        contactId: 'anyIdHere',
        urlRef: window.location.host
    };

}