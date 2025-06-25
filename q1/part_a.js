function translate(text) {

    const consonants = 'bcdfghjklmnpqrstvwxyz';

    let result = '';

    for (let i = 0; i < text.length; i++) {
        const char = text[i];

        
        if (consonants.includes(char.toLowerCase())) {
           
            result += char + 'o' + char; 
        } else {
            result += char;
        }
    }

    return result;
}

console.log('--- Testing Part (a) ---');
const originalText = "this is fun";
const translatedText = translate(originalText);
console.log(`Original: "${originalText}"`);
console.log(`Translated: "${translatedText}"`); 

const anotherTest = "JavaScript";
console.log(`\nOriginal: "${anotherTest}"`);
console.log(`Translated: "${translate(anotherTest)}"`); 