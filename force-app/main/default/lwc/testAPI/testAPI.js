import { LightningElement } from 'lwc';

export default class TestAPI extends LightningElement {
    connectedCallback() {
        console.log('testAPI connectedCallback');
    }

    //call NASA API using fetch
    getNasaData() {
        fetch('https://api.nasa.gov/planetary/apod?api_key=DEMO_KEY', {
            method: "GET"
        })
            .then(response => response.json())
            .then(data => {
                console.log(data);
            });
    }
}