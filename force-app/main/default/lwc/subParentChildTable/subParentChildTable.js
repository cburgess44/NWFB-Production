import { LightningElement, api } from 'lwc';

export default class SubParentChildTable extends LightningElement {
    _object;

    @api
    get object() {
        return this._object;
    }
    set object(value){

        console.log('value stringified ', JSON.stringify(value));
        this._object = value;
    }


}