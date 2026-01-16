/**
 * Created by dudunato on 22/10/22.
 */


export const dates = {
    sfDate: (date) => {
        return date.getFullYear() + '-' + addZero(date.getMonth() + 1) + '-' + addZero(date.getUTCDate());
    }
};

const addZero = (n) => {
    n = n.toString();
    return n[1] ? n : '0' + n;
}