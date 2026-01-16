/**
 * Created by Gustavo on 10/04/23.
 */

import {LightningElement} from 'lwc';

export const groupByKey = (array, key, concat) => {
    if (concat === undefined) concat = true;
    return array.reduce(function (objectsByKeyValue, obj) {
        const value = obj[key];
        objectsByKeyValue[value] = concat ? (objectsByKeyValue[value] || []).concat(obj) : obj;
        return objectsByKeyValue;
    }, {});
};

export const getSfDate = (date) => {
    return date.getFullYear() + '-' + addZero(date.getMonth() + 1) + '-' + addZero(date.getDate());
};

const addZero =  (n) => {
    n = n.toString();
    return n[1] ? n : '0' + n;
}