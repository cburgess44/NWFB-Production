/**
 * Created by dudunato on 18/10/22.
 */

import {dates} from 'c/generalUtilities';

export const twoWeeksDateRange = (currentDate) => {
    const currentClone = new Date(currentDate.getTime());

    // First Sunday of the week, then we shift one more week
    //const firstTmp = (currentDate.getDate() - currentDate.getDay());
    const firstTmp = currentDate.getDate();
    // last day is the first day + 13
    const lastTmp = firstTmp + 14;

    const firstDay = new Date(currentDate.setDate(firstTmp));
    const lastDay = new Date(currentClone.setDate(lastTmp));

    return {
        firstDay: firstDay,
        firstDaySF: dates.sfDate(firstDay),
        lastDay: lastDay,
        lastDaySF: dates.sfDate(lastDay)
    };
};

export const moveTwoWeeks = (currentDate, backwards) => {
    const currentClone = new Date(currentDate);

    const firstDayShift = backwards ? -15 : 15;
    const lastDayShift = backwards ? -1 : 1;

    const firstDate = new Date(currentDate.setDate(currentDate.getUTCDate() + firstDayShift));
    const lastDate = new Date(currentClone.setDate(currentClone.getUTCDate() + lastDayShift));

    const dateRange = {
        firstDay: backwards
            ? firstDate
            : lastDate,
        lastDay: backwards
            ? lastDate
            : firstDate,
    };

    return {
        ...dateRange,
        firstDaySF: dates.sfDate(dateRange.firstDay),
        lastDaySF: dates.sfDate(dateRange.lastDay),
    };
}

export const setOldTrips = (firstDayShift, lastDayShift) => {

        const firstDate = new Date(firstDayShift);
        const lastDate = new Date(lastDayShift);

        const dateRange = {
            firstDay: firstDate,
            lastDay: lastDate

        };

        return {
            ...dateRange,
            firstDaySF: dates.sfDate(dateRange.firstDay),
            lastDaySF: dates.sfDate(dateRange.lastDay),
        };
}