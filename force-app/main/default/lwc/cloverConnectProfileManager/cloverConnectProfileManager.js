/**
 * Created by dudunato on 06/06/22.
 */

import {api, LightningElement, track} from 'lwc';

import getMerchantId from '@salesforce/apex/CloverConnectController.getMerchantId'
import getProfile from '@salesforce/apex/CloverConnectController.getProfile'
import saveProfile from '@salesforce/apex/CloverConnectController.saveProfile'
import deleteProfile from '@salesforce/apex/CloverConnectController.deleteProfile'
import LightningConfirm from 'lightning/confirm';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import {profileLabels} from './constants';

const APPROVED_RESPONSE = 'A';

export default class CloverConnectProfileManager extends LightningElement {
    @api
    merchantSetting = 'MerchantSetting';

    @api
    profileId;

    @track
    actionsController;

    merchId;
    accounts;
    loading;

    label = profileLabels;

    constructor() {
        super();
        this.actionsController = {
            editMode: false,
            editLabel: this.label.cc_EditMethods,
            editButtonVariant: 'brand-outline',
            newAccountForm: false
        };
        this.accounts = [];
        this.loading = true;
    }

    get noAccounts() {
        return this.accounts && this.accounts.length <= 0;
    }

    get showAccounts() {
        return this.accounts.length > 0 && !this.actionsController.newAccountForm;
    }

    async connectedCallback() {
        await this.setMerchant();
        await this.fetchAccounts();
    }

    async setMerchant() {
        this.merchId = await getMerchantId({
            settingDeveloperName: this.merchantSetting
        });
    }

    async fetchAccounts() {
        if (!this.profileId) {
            this.loading = false;
            return;
        }

        this.accounts = await getProfile({
            profileId: this.profileId,
            merchId: this.merchId
        });

        if (!this.accounts || this.accounts.length <= 0) {
            this.loading = false;
            return;
        }

        if (this.accounts.length === 1 && this.accounts[0].resptext === 'Profile not found') {
            this.accounts = [];
            this.loading = false;
            return;
        }

        let index = 0;

        for (const account of this.accounts) {
            account.last4 = account.token.slice(-4);
            account.key = account.last4 + index;
            account.default = account.defaultacct === 'Y';

            if (account.expiry) {
                account.expiry = account.expiry.substring(0, 2) + '/' + account.expiry.substring(2, 4);
            }

            switch (account.accttype) {
                case 'VISA':
                    account.brand = 'Visa';
                    break;
                case 'MC':
                    account.brand = 'Mastercard';
                    break;
                case 'DISC':
                    account.brand = 'Discover';
                    break;
                case 'AMEX':
                    account.brand = 'American Express';
                    break;
                case 'ECHK':
                    account.brand = 'Bank Account';
                    account.expiry = 'N/A';
                    break;
                default:
                    account.brand = account.accttype;
                    break;
            }

            index++;
        }

        this.loading = false;
        if (this.actionsController.editMode) this.handleEditMode();
        console.log('accounts', JSON.parse(JSON.stringify(this.accounts)));
    }

    async handleAccountSave(event) {
        if (!this.profileId) this.profileId = event.detail.profileid;
        await this.fetchAccounts();
        this.toggleAccountForm();
        const defaultAccount = this.accounts.find((acc) => acc.default);
        this.dispatchEvent(
            new CustomEvent(
                'profilesave',
                {
                    detail: {
                        profileId: this.profileId,
                        token: defaultAccount.token
                    }
                }
            )
        ); 
    }

    async makeAccountDefault(event) {
        this.loading = true;
        const currentAccount = {...event.target.value};
        currentAccount.profile = `${this.profileId}/${currentAccount.acctid}`;
        currentAccount.merchid = this.merchId;
        currentAccount.defaultacct = 'Y';
        const saveResponse = await saveProfile({
            profileJSON: JSON.stringify(currentAccount),
        });
        console.log('current account ' + currentAccount);

        if (saveResponse.errors || APPROVED_RESPONSE !== saveResponse.respstat) {
            const errorMessage = saveResponse.errors
                ? saveResponse.errors.message
                : saveResponse.resptext;

            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message: errorMessage,
                variant: 'error',
                mode: 'sticky'
            }));

            this.loading = false;
            return;
        }

        this.dispatchEvent(
            new CustomEvent(
                'changeddefaultmethod',
                {
                    detail: {
                        accountId: currentAccount.acctid,
                        token: currentAccount.token
                    }
                }
            )
        );

        this.dispatchEvent(new ShowToastEvent({
            title: '',
            message: this.label.cc_MethodUpdated,
            variant: 'success',
            mode: 'dismissible'
        }));

        await this.fetchAccounts();
    }

    async deleteAccount(event) {
        const currentAccount = event.target.value;

        const confirmed = await LightningConfirm.open({
            label: this.label.cc_DeleteMethod,
            message: this.label.cc_AreYouSureYouWantToDeleteThisMethod,
            variant: 'header',
            theme: 'warning'
        });

        if (!confirmed) return;

        this.loading = true;

        const otherAccount =  this.accounts.find((acc) => (acc.acctid !== currentAccount.acctid));

        const fakeEvent = otherAccount
            ? {target: {value: otherAccount}}
            : null;

        if (otherAccount && currentAccount.default) await this.makeAccountDefault(fakeEvent);

        const deleteResponse = await deleteProfile({
            profileId: this.profileId,
            accountId: currentAccount.acctid,
            merchId: this.merchId
        });

        if (deleteResponse.errors || APPROVED_RESPONSE !== deleteResponse.respstat) {
            const errorMessage = deleteResponse.errors
                ? deleteResponse.errors.message
                : deleteResponse.resptext;

            this.dispatchEvent(new ShowToastEvent({
                title: '',
                message: errorMessage,
                variant: 'error',
                mode: 'sticky'
            }));


            this.loading = false;
            return;
        }

        this.dispatchEvent(new CustomEvent('deleteaccount'));

        if (!otherAccount) {
            this.dispatchEvent(new CustomEvent('deleteprofile'));
        }

        this.dispatchEvent(new ShowToastEvent({
            title: '',
            message: this.label.cc_MethodDeleted,
            variant: 'success',
            mode: 'dismissible'
        }));

        await this.fetchAccounts();
    }


    toggleAccountForm() {
        this.actionsController.newAccountForm = !this.actionsController.newAccountForm;
    }

    handleEditMode() {
        let currentMode = this.actionsController.editMode;
        this.actionsController = {
            editMode: !currentMode,
            editLabel: currentMode ? this.label.cc_EditMethods : this.label.cc_Editing,
            editButtonVariant: currentMode ? 'brand-outline' : 'brand',
        };
    }
}