/**
 * Created by Gustavo on 14/12/23.
 */

import {api, LightningElement} from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class PhotoModal extends LightningElement {


    @api
    photoUrl;

    @api
    modalTitle;

    handleCloseModal() {
        this.dispatchEvent(new CloseActionScreenEvent());
        this.dispatchEvent(new CustomEvent('closemodal'));
    }
}