// File: part_a.js
function createMonthConverter() {
    const months = [
        "January", "February", "March", "April", "May", "June",
        "July", "August", "September", "October", "November", "December"
    ];

    return function(monthNumber) {
        if (isNaN(monthNumber) || monthNumber === null || monthNumber === '') {
            return "Bad Number";
        }
        const num = Math.floor(Number(monthNumber));
        if (num >= 1 && num <= 12) {
            return months[num - 1];
        } else {
            return "Bad Number";
        }
    };
}

const getMonthName = createMonthConverter();
console.log(`Input 3: ${getMonthName(3)}`);
console.log(`Input 7.8: ${getMonthName(7.8)}`);
console.log(`Input 13: ${getMonthName(13)}`);
console.log(`Input 'hello': ${getMonthName('hello')}`);