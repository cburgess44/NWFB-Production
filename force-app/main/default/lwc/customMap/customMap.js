import { LightningElement, track, api } from 'lwc';

export default class CustomMap extends LightningElement {

    @api url;
    @api origin;
    @api destination;
    @api height = '500px';
    @api referrerPolicy = 'no-referrer';
    @api sandbox;
    @api width = '100%';
    @api get iframeUrl() {
        return this.url;
      }
      set iframeUrl(value) {
        this.setAttribute('url', value);
        this.url = value;
      }

    map;
    renderedCallback() {

        console.log('window.location.origin;  ### '+window.location.origin)
        //this.url =window.location.origin+'/apex/googleMapsApi?t='+n+'&startpoint='+sp+'&endpoint='+ep+'&waypoints=';
        // Load the Google Maps JavaScript API
    }

}