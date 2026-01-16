/**
 * Created by dudunato on 31/05/22.
 */

import {api, LightningElement} from 'lwc';

import {cardTokenizerLabels, iframeCSS} from './constants';

export default class CloverConnectCardTokenizer extends LightningElement {

    @api
    name;

    @api
    value;

    @api
    required;

    labels = cardTokenizerLabels;
    invalidCreditCard = false;
    renderIFrame = true;

    connectedCallback() {
        this.initTokenListener();
        this.required = true;
    }

    get iFrameURL() {
        return this.labels.cc_TokenizerURL + iframeCSS;
    }

    @api
    checkValidity() {
        return this.value != null;
    }

    @api
    reportValidity() {
        this.invalidCreditCard = !this.checkValidity();
    }

    @api
    reset() {
        this.renderIFrame = false;
        setTimeout(() => this.renderIFrame = true, 10);
    }

    initTokenListener() {
        window.addEventListener('message', (event) => {
            if (!event.origin.includes('cardconnect.com')) return;

            let data =  JSON.parse(event.data);

            if (data.validationError) {
                this.invalidCreditCard = true;
                this.value = null;
            }

            const token = data.message;
            if (token) {
                this.value = token;
                this.invalidCreditCard = false;
            }

            try {

                this.dispatchEvent(new CustomEvent(
                    'change',
                    {
                        detail: {
                            name: this.name,
                            value: this.value
                        }
                    }
                ));

            } catch (e) {
                // sometimes a ghost call happens, and it throws [NoErrorObjectAvailable] Script error.
                console.error(e);
            }

        }, false);
    }


}