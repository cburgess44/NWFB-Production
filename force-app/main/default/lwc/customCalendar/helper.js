/**
 * Created by dudunato on 06/08/22.
 */


export const sfDate = (date) => {
    return date.getFullYear() + '-' + addZero(date.getMonth() + 1) + '-' + addZero(date.getUTCDate());
};

const addZero = (n) => {
    n = n.toString();
    return n[1] ? n : '0' + n;
}

export const getDates = (date, time) => {
    const onlyTime = time.slice(0, -2);
    const period = time.slice(-2);

    const start = new Date(Date.parse(`${date} ${onlyTime} ${period}`));
    const end = new Date(start.getTime());
    end.setMinutes(end.getMinutes() + 45);

    return {
        start: start,
        end: end
    };
};

export const normalizePosition = (scope, contextMenu, mouseX, mouseY) => {
    // ? compute what is the mouse position relative to the container element (scope)
    let {
        left: scopeOffsetX,
        top: scopeOffsetY,
    } = scope.getBoundingClientRect();

    scopeOffsetX = scopeOffsetX < 0 ? 0 : scopeOffsetX;
    scopeOffsetY = scopeOffsetY < 0 ? 0 : scopeOffsetY;

    const scopeX = mouseX - scopeOffsetX;
    const scopeY = mouseY - scopeOffsetY;

    // ? check if the element will go out of bounds
    const outOfBoundsOnX = scopeX + contextMenu.clientWidth > scope.clientWidth;

    const outOfBoundsOnY = scopeY + contextMenu.clientHeight > scope.clientHeight;

    let normalizedX = mouseX;
    let normalizedY = mouseY;

    // ? normalize on X
    if (outOfBoundsOnX) normalizedX = scopeOffsetX + scope.clientWidth - contextMenu.clientWidth;

    // ? normalize on Y
    if (outOfBoundsOnY) normalizedY = scopeOffsetY + scope.clientHeight - contextMenu.clientHeight;

    return { normalizedX, normalizedY };
};