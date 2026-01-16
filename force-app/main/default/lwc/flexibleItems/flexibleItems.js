/**
 * Created by Gustavo on 10/04/23.
 */

import {api, LightningElement, track} from 'lwc';
import getPicklist from '@salesforce/apex/SObjectCRUDController.getPicklist';
import listSObjects from '@salesforce/apex/SObjectCRUDController.listSObjects';
import {groupByKey} from 'c/utils';
import USER_ID from '@salesforce/user/Id';
import {ShowToastEvent} from "lightning/platformShowToastEvent";

export default class FlexibleItems extends LightningElement {

    @api
    serviceId;

    @api
    showFlexibleProducts;

    @api
    showStaffRequestableProducts;

    @track
    productCategories = [];

    service = {};

    @track
    user = {};

    async connectedCallback() {
        await this.loadUserInfo();
        await this.loadServiceData();
        await this.loadProductCategories();
        await this.loadProducts();
    }

    async loadUserInfo() {
        try {
           const currentUser = await listSObjects({
               objectName: 'User',
               fields: [
                   'Id',
                   'Profile.Name',
               ],
               filters: `AND Id = '${USER_ID}'`
           });
           this.user = currentUser[0];
        } catch (error) {
           console.error('Error: ', error);
        }
    }

    async loadServiceData() {
        try {
           const service = listSObjects({
               objectName: 'Service__c',
               fields: [
                   'Id',
                   'Name',
                   'RecordType.DeveloperName'
               ],
               filters: `AND Id = '${this.serviceId}'`
           });

           this.service = service[0];
        } catch (error) {
           console.error('Error: ', error);
        }
    }

    async loadProductCategories() {
        try {
            const productCategories = await getPicklist({
                objectName: 'Product__c',
                fieldName: 'Category__c'
            });

            this.productCategories = productCategories.sort((a, b) => a.label.localeCompare(b.label));

        } catch (error) {
            console.error('Error: ', error);
        }
    }

    async loadProducts() {
        if (this.user !== undefined && this.user.Profile.Name === 'NWFB Platform Volunteer') {
            try {
                let products = await listSObjects({
                    objectName: 'Product__c',
                    fields: [
                        'Id',
                        'Name',
                        'Category__c'
                    ],
                    filters: `AND Flexible__c = TRUE`
                });
                products.sort((a, b) =>
                    a.Name.localeCompare(b.Name)
                );
                products = products.map(item => {
                    return {
                        id: item.Id,
                        name: item.Name,
                        category: item.Category__c
                    }
                });
    
                const categorizedProducts = groupByKey(products, 'category');
    
                this.productCategories.forEach(category => {
                    category.products = categorizedProducts[category.label] || null;
                });
    
            } catch (error) {
                console.error('Error: ', error);
            }

        } else {
            try {
                let products = await listSObjects({
                    objectName: 'Product__c',
                    fields: [
                        'Id',
                        'Name',
                        'Category__c'
                    ],
                    filters: `AND Staff_Requestable__c = TRUE`
                });

                products.sort((a, b) =>
                    a.Name.localeCompare(b.Name)
                );
    
                console.log('Products ' + products.length);
    
                products = products.map(item => {
                    return {
                        id: item.Id,
                        name: item.Name,
                        category: item.Category__c
                    }
                });
    
                const categorizedProducts = groupByKey(products, 'category');
    
                this.productCategories.forEach(category => {
                    category.products = categorizedProducts[category.label] || null;
                });
    
            } catch (error) {
                console.error('Error: ', error);
            }
        }
        
    }

    @api
    async updateItems() {
        await this.loadProducts();
    }

    handleAddProduct(event) {
        const productId = event.target.dataset.productId;
        if (productId) {
            this.dispatchEvent(
                new CustomEvent('addproduct', {
                    detail: productId
                })
            );
        } else {
            this.dispatchEvent(new ShowToastEvent({
                Title: 'Something went wrong!',
                message: 'Something went wrong, please try to add the item again',
                variant: 'error',
                mode: 'dismissable',
            }));
        }


    }
}