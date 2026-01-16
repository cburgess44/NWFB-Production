/**
 * Created by dudunato on 27/05/22.
 */

import {api, LightningElement, track} from 'lwc';

import {normalizeInputData, validateEmail, formatDate} from './helper';

import {formLabels, RESPONSE_STATUS} from './constants';

import authorize from '@salesforce/apex/CloverConnectController.authorize'
import getMerchantId from '@salesforce/apex/CloverConnectController.getMerchantId'
import getProfile from '@salesforce/apex/CloverConnectController.getProfile'
import saveProfile from '@salesforce/apex/CloverConnectController.saveProfile'
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class CloverConnectPaymentForm extends LightningElement {

    @api
    merchantSetting;

    @api
    backgroundColor;

    @api
    billingPlanName;

    // @api
    // profileId = '15309722213283839773';

    @api
    profileId;

    @api
    profileMode;

    @api
    userFields;

    @api
    enableAnonymous;

    @api
    enableComments;

    @api
    enableSchedulingPlan;

    @api
    enableEmailCapture;

    @api
    paymentType;

    @api
    lockedAmount;

    @api
    reload(amount) {
         this.authData.amount = amount;
         console.log('amount', this.authData.amount);
    }


    @track
    currentFormType;

    @track
    authData;

    @track
    billingPlan;

    @track
    accounts;

    label;
    schedulingOptions;
    formType;
    unpristineFields;
    validToAuthorize;
    authorizingPayment;
    authorizeError;
    authorizeErrorMessage;
    accountByProfile;
    userFieldsManager;
    enableSaveForFutureController;

    constructor() {
        super();
        this.init();
    }


    init() {
        this.merchantSetting = 'MerchantSetting';
        this.backgroundColor = 'white';
        this.userFields = {};
        this.currentFormType = 'card';
        this.authData = {};
        this.billingPlan = {};
        this.accounts = [];
        this.label = formLabels;
        this.paymentType = 'all';
        this.formType = [
            {
                label: 'Card',
                value: 'card'
            },
            {
                label: 'eCheck',
                value: 'eCheck'
            },
        ];
        this.unpristineFields = {};
        this.validToAuthorize = false;
        this.authorizingPayment = false;
        this.authorizeError = false;
        this.authorizeErrorMessage = '';
        this.accountByProfile = {};
        this.userFieldsManager = {};
    }

    async connectedCallback() {
        await this.setPreDefinedAuthData();
        await this.getAccounts();
        this.setPaymentType();
        this.setSchedulingPlan();
    }

    async setPreDefinedAuthData() {
        this.authData = {merchid: this.authData.merchid};

        if (this.profileMode) {
            this.authData.profile = this.profileId;
            this.authData.cofpermission = 'y';
            this.authData.profileupdate = 'y';
        } else {
            this.authData.capture = 'y';
            this.authData.ecomind = 'E';

            if (this.profileId) this.enableSaveForFutureController = false;
        }

        if (this.userFields) {
            this.userFieldsManager = {...this.userFields};
            this.authData.userFields = this.userFieldsManager;
        }

        if (this.authData.merchid) return;

        this.authData.merchid = await getMerchantId({
            settingDeveloperName: this.merchantSetting
        });

        if (this.lockedAmount) {
            this.authData.amount = this.lockedAmount;
            this.unpristineFields['amount'] = true;
        }

        this.billingPlan = {
            merchId: this.authData.merchid,
            every: 1,
            billingPlanName: this.billingPlanName,
            timeSpan: 0,
            untilCondition: 'C',
            currencySymbol: '$',
            startDate: formatDate(new Date()),
            options: [{name: 'email_receipt', value: '0'}]
        };
    }

    setPaymentType() {
        if (this.paymentType === 'all') return;
        this.currentFormType = this.paymentType;
    }

    setSchedulingPlan() {
        if (!this.enableSchedulingPlan) return;

        let options = [
            {
                label: 'One Time',
                value: 0
            },
            {
                label: 'Monthly',
                value: 3
            },
            {
                label: 'Yearly',
                value: 4
            }
        ];

        options = options.filter((o) => {
            const label = o.label.toLowerCase();
            if (label === 'one time' || this.enableSchedulingPlan === 'all') return true;
            return label === this.enableSchedulingPlan
        });

        this.schedulingOptions = options;
    }

    @api
    async getAccounts() {
        if (!this.authData.merchid || !this.profileId || this.profileMode) return;

        this.accounts = await getProfile({
            profileId: this.profileId,
            merchId: this.authData.merchid
        });

        if (!this.accounts || this.accounts.length <= 0) return;

        if (this.accounts.length === 1 && this.accounts[0].resptext === 'Profile not found') {
            this.accounts = [];
            this.loading = false;
            return;
        }

        let defaultAccount = '';
        for (const account of this.accounts) {
            const last4 = account.token.slice(-4);
            account.label = `${account.name} (${last4})`;
            account.value = `${this.profileId}/${account.acctid}`;

            if (account.defaultacct === 'Y') defaultAccount = account.value;

            this.accountByProfile[account.value] = {
                token: account.token,
                type: account.accttype
            };
        }

        this.accounts.unshift({
                label: 'Select a payment method',
                value: 'Select a payment method'
        });

        this.accounts.push({
            label: 'New Account',
            value: this.profileId
        });

        // this.authData.profile = defaultAccount;
        this.authData.profile = 'Select a payment method';
        this.currentFormType = 'profile';
    }

    @api
    get enableSaveForFuture() {
        return this.enableSaveForFutureController;
    }

    set enableSaveForFuture(enable) {
        this.enableSaveForFutureController = enable;
    }

    get cardFormType() {
        return this.currentFormType === 'card';
    }

    get eCheckFormType() {
        return this.currentFormType === 'eCheck';
    }

    get showFormType() {
        return this.currentFormType !== 'profile' && this.paymentType === 'all';
    }

    get invalidToAuthorize() {
        return !this.validToAuthorize || this.authorizingPayment;
    }

    get showPaymentAccounts() {
        return this.profileId && !this.profileMode;
    }

    handleSchedulingPlanChange(event) {
        this.billingPlan.timeSpan = Number(event.detail.value);
    }

    handleFormTypeChange(event) {
        this.currentFormType = event.detail.value;
    }

    handleAccountChange(event) {
        const selectedAccount = event.detail.value;

        if (selectedAccount === this.profileId) {
            this.currentFormType = 'card';
            this.authData.profile = this.profileId;
            this.authData.cofpermission = 'y';
        } else {
            this.authData.profile = selectedAccount;
            this.authData.account = this.accountByProfile[selectedAccount].token;
            this.authData.accttype = this.accountByProfile[selectedAccount].type;
            this.currentFormType = 'profile';
        }
    }

    handleAuthDataChange(event) {
        const origin = event.target ? event.target : event.detail;

        this.authData[origin.name] = normalizeInputData(event);
        this.unpristineFields[origin.name] = true;
        this.validateInputs();
        if (this.authorizeError) this.authorizeError = false;
    }

    handleUserFieldsChange(event) {
        this.userFieldsManager[event.target.name] = event.target.type === 'checkbox'
            ? event.target.checked
            : event.target.value;

        if (this.userFieldsManager.saveForFuture) this.authData.profile = 'Y';

        this.authData.userfields = this.userFieldsManager;
    }

    async handleAuthorize() {
        console.log('authData', JSON.stringify(this.authData));
        this.authorizingPayment = true;

        // need to normalize the decimals, otherwise CloverConnect don't know what to do
        this.authData.amount = Number(this.authData.amount).toFixed(2);
        this.billingPlan.amount = this.authData.amount;

        const authorizeResponse = await authorize({
            authorizeJSON: JSON.stringify(this.authData),
            billingPlanJSON: this.billingPlan.timeSpan > 0 // we only send billing plan if it's a recurring payment
                ? JSON.stringify(this.billingPlan)
                : null
        });

        await this.handleCCResponse(authorizeResponse);

        this.dispatchEvent(new CustomEvent('aftersubmit', {detail: authorizeResponse}));

        this.authorizingPayment = false;
    }

    async handleCCResponse(authorizeResponse) {
        let responseOk = true;

        if (authorizeResponse.errors || authorizeResponse.respstat !== RESPONSE_STATUS.APPROVED) {
            this.authorizeErrorMessage = authorizeResponse.errors
                ? authorizeResponse.errors.message
                : authorizeResponse.resptext;
            this.authorizeError = true;
            responseOk = false;
        } else {
            await this.resetForm();
        }

        return responseOk;
    }

    async handleProfileSave() {
        this.authorizingPayment = true;

        const profileSaveResponse = await saveProfile({
            profileJSON: JSON.stringify(this.authData)
        });

        if (await this.handleCCResponse(profileSaveResponse)) {
            this.dispatchEvent(new ShowToastEvent({
                title: 'Success',
                message: this.label.cc_AccountSavedSuccessfully,
                variant: 'success',
                mode: 'dismissible'
            }));
            this.dispatchEvent(new CustomEvent('profilesave', {detail: profileSaveResponse}));
        }

        this.authorizingPayment = true;
    }

    handleProfileCancel() {
        this.dispatchEvent(new CustomEvent('profilecancel'));
    }

    validateInputs() {
        let nRequiredInputs = 0;
        const selectors = this.cardFormType ? 'lightning-input, c-clover-connect-card-tokenizer' : 'lightning-input';
        const uniqueInputs = {}; // to count only one input with the same name (i.e: account on eCheck confirmation)
        const inputs = [...this.template.querySelectorAll(selectors)].filter(i => {
            if (uniqueInputs[i.name]) return false

            if (i.required) {
                nRequiredInputs++;
                uniqueInputs[i.name] = true;
            }

            return i.required && this.unpristineFields[i.name];
        });

        if (inputs.length === 0) return;

        const validInputs = inputs.reduce((validSoFar, input) => {
            this.reportInputValidation(input);
            return validSoFar && input.checkValidity();
        }, true);

        this.validToAuthorize = validInputs && inputs.length === nRequiredInputs;
    }

    reportInputValidation(input) {
        if (input.name === 'email') {
            if (validateEmail(input.value)) input.setCustomValidity('');
            else input.setCustomValidity('Invalid email!');
        }

        input.reportValidity();
    }

    async resetForm() {
        this.unpristineFields = {};
        if (this.cardFormType) this.template.querySelector('c-clover-connect-card-tokenizer').reset();
        await this.setPreDefinedAuthData();
    }
}