/**
 * Created by Sytech on 07/06/2023.
 */

import { LightningElement } from 'lwc';
import LightningDatatable from 'lightning/datatable';
import customButtonGroupTemplate from './buttonGroupType.html';
import testTemplate from './test.html';

export default class ButtonGroupType extends LightningDatatable  {
        static customTypes = {
            customButtons: {
                template: customButtonGroupTemplate,
                standardCellLayout: true,
                typeAttributes: ['buttons'],
            },

        }
}