/**
 * Created by Sytech on 04/01/2024.
 */

import {LightningElement, wire, api, track} from 'lwc';
import fetchRecords from '@salesforce/apex/RelatedListController.fetchRecords';
import {getObjectInfo} from "lightning/uiObjectInfoApi";
import {NavigationMixin} from 'lightning/navigation';
import {refreshApex} from '@salesforce/apex';

export default class StopRelatedList  extends NavigationMixin(LightningElement) {
    @api
    recordId;

    @track
    titleWithCount;

    @api
    objectName;

    @api
    tableData = [];

    @api
    relationshipApiName;

    @api
    field1;

    @api
    field2;

    @api
    field3;

    @api
    field4;

    @api
    field5;

    @api
    field6;

    @track
    fieldValue;

    @api
    parentFieldAPIName;

    @api
    parentObjectName;

    @api
    parentFieldName;

    @api
    refField;

    @wire(fetchRecords, {listValues: '$vals'})
    accountData(value) {
        console.log('value', value);
        this.fetchData = value;
        const data = value.data;
        const error = value.error;

        if (data) {
            this.tableData = [];
            this.fetchTableData(data?.listRecords);

            if (data.recordCount != null) {
                if (data.recordCount > 3) {
                    this.titleWithCount = 'Stops ' + ' (3+)';
                    this.countBool = true;
                } else {
                    this.countBool = false;
                    this.titleWithCount = 'Stops '+ ' (' + data.recordCount + ')';
                }

                if (typeof this.titleWithCount === 'undefined') {
                    this.titleWithCount = 'Stops ' + '(' + data.recordCount + ')';
                }
            }
        } else if (error) {
            console.error('Error: ', error);
        }
    }

    get vals() {
            return this.recordId
                + '-'
                + this.objectName
                + '-'
                + this.parentFieldAPIName
                + '-'
                + this.field1
                + ','
                + this.field2
                + ','
                + this.field3
                + ','
                + this.field4
                + ','
                + this.field5;
    }

    fetchTableData(listRecords) {
            this.tableData = [];

            listRecords.forEach((element) => {
                let obj = JSON.parse(JSON.stringify(element));

                obj['recordUrl'] = '/' + element.Id;
                obj['serviceUrl'] = '/' + element.Service__c;
                obj['ServiceName'] = element.Service__r?.Name;
                obj['ServiceStatus'] = element.Service__r?.Status__c;
                obj['Name'] = element.Name;
                obj.field1 = obj[this.field1];
                obj.field2 = obj[this.field2];
                obj.field3 = obj[this.field3];
                obj.field4 = obj[this.field4];
                obj.field5 = obj[this.field5];



                this.tableData.push(obj);
                this.tableData = this.tableData.sort((a,b) => (a.StopOrder__c > b.StopOrder__c) ? 1:((b.StopOrder__c > a.StopOrder__c) ? -1:0));
                console.log('obj', obj.servicedUrl);
                console.log('element', element);
            });
    }

    @wire(getObjectInfo, {objectApiName: 'Stop__c'})
    objectInfo;



    get iconName() {
        if (!this.objectInfo.data || !this.objectInfo.data.themeInfo.iconUrl) {
            return ('standard:custom')
        }

        let url = this.objectInfo.data ? this.objectInfo.data.themeInfo.iconUrl : '';
        let name = url.substring(url.lastIndexOf("/"), url.length);
        url = url.substring(0, url.lastIndexOf("/"));
        let type = url.substring(url.lastIndexOf("/"), url.length);
        let icName = this.replaceAt(url.lastIndexOf("/"), ":", type + name).replace("/", "");
        icName = icName.substring(0, icName.length - 9).replace("/", ":");
        return icName;
    }

    replaceAt(index, replacement, str) {
        return (
            str.substr(0, index) +
            replacement +
            str.substr(index + replacement.length)
        );
    }
    connectedCallback() {
        this.fieldValue = this.recordId;
    }

    navigateToRelatedList() {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: this.parentObjectName,
                relationshipApiName: this.relationshipApiName,
                actionName: 'view'
            }
        });

        this.saveListener = setInterval(async () => {
            if (location.pathname !== '/lightning/o/Stop__c/new') {
                await refreshApex(this.fetchData);
                clearInterval(this.saveListener);
            }
        }, 500);
    }
}