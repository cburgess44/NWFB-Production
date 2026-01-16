import { LightningElement, api, wire, track } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import getFieldset from '@salesforce/apex/FieldsetService.getFieldset';

export default class CustomRelatedRecord extends LightningElement {
  @api recordId;
  @api relatedField;
  @api objectName;
  @api layoutType;
  @api fieldSetName;
  @api cardName;
  @track fieldSet = ['Name']

  replaceAt(index, replacement, str) {
    return (
      str.substr(0, index) +
      replacement +
      str.substr(index + replacement.length)
    );
  }

  @wire(getRecord, { recordId: "$recordId", fields: "$relatedField" })
  customObject;

  @wire(getObjectInfo, { objectApiName: "$objectName" })
  objectInfo;

  @wire(getFieldset, { sObjectName: "$objectName", fieldSetName: '$fieldSetName' })
  fieldSet({ error, data }){
    if(data){
      console.log(Object.keys(data.fieldset))
      this.fieldSet = Object.keys(data.fieldset);
    } else if (error){
      console.log(error);
    }
  }

  get cardTitle() {
    return this.cardName;
  }

  get iconName() {
    var url = this.objectInfo.data.themeInfo.iconUrl;
    var name = url.substring(url.lastIndexOf("/"), url.length);
    url = url.substring(0, url.lastIndexOf("/"));
    var type = url.substring(url.lastIndexOf("/"), url.length);
    var icName = this.replaceAt(url.lastIndexOf("/"), ":", type + name).replace(
      "/",
      ""
    );
    icName = icName.substring(0, icName.length - 9).replace("/", ":");
    return icName;
  }

  get relatedRecordId() {
    var field = this.relatedField;
    field = field.substring(field.lastIndexOf(".") + 1, field.length);
    return this.customObject.data.fields[field].value;
  }
}