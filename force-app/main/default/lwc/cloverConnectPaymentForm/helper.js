/**
 * Created by dudunato on 03/06/22.
 */

export const validateEmail = (email) => {
    if (email != null && email.length > 0) {
        const re = new RegExp(/^(([0-9a-z]+((\.|\-|\_|\+)[0-9a-z]+)*))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/);
        return re.test(email);
    }
    return false;
};

export const normalizeInputData = (event) => {
    const origin = event.target ? event.target : event.detail;

    switch (origin.name) {
        case 'email':
            event.detail.value = event.detail.value.toLowerCase();
            break;

        case 'expiry':
            event.detail.value = validateExpiration(event.detail.value);
            break;
    }

    return event.detail.value;
};

const validateExpiration = (value) => {

    let number = String(value);

    let cleanNumber = '';
    for (let i = 0; i < number.length; i++) {
        if (i === 1 && number.charAt(i) === '/') cleanNumber = 0 + number.charAt(0);

        if (/^\d+$/.test(number.charAt(i))) cleanNumber += number.charAt(i);
    }

    let formattedMonth = '';
    for (let i = 0; i < cleanNumber.length; i++) {
        if (!/^\d+$/.test(cleanNumber.charAt(i))) continue;

        if (i === 0 && cleanNumber.charAt(i) > 1) {
            formattedMonth += 0;
            formattedMonth += cleanNumber.charAt(i);
            formattedMonth += '/';
        } else if (i === 1) {
            formattedMonth += cleanNumber.charAt(i);
            formattedMonth += '/';
        } else if (i === 2 && cleanNumber.charAt(i) < 2) {
            formattedMonth += '20' + cleanNumber.charAt(i);
        } else {
            formattedMonth += cleanNumber.charAt(i);
        }
    }

    return formattedMonth;
};

export const formatDate = (date) => {
    let year = date.getFullYear();
    let month = (1 + date.getMonth()).toString().padStart(2, '0');
    let day = date.getDate().toString().padStart(2, "0");
    return month + day + year;
};