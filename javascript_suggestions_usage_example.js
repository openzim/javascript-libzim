// JavaScript usage examples for SuggestionSearcher in javascript-libzim
// This would be used in the Web Worker or main thread after compilation

// First, load an archive
Module.loadArchive("path/to/your/file.zim");

// APPROACH 1: Simple function approach (easiest to use)
// This mirrors the existing search() function pattern
console.log("=== Simple Function Approach ===");

const query = "kiwix";
const maxResults = 10;

// Get suggestions using the simple function
const suggestions = Module.suggest(query, maxResults);
console.log(`Found ${suggestions.size()} suggestions for "${query}"`);

// Iterate through results
for (let i = 0; i < suggestions.size(); i++) {
    const entry = suggestions.get(i);
    console.log(`${i}: ${entry.getTitle()} (${entry.getPath()})`);
}

// APPROACH 2: Class-based approach (more similar to Node.js/Python APIs)
// This provides more control and follows the same pattern as the other bindings
console.log("\n=== Class-based Approach ===");

// Create a suggestion searcher
const suggestionSearcher = new Module.SuggestionSearcher();

// Search for suggestions
const suggestionSearch = suggestionSearcher.suggest(query);

// Get the number of matches
const matchCount = suggestionSearch.getEstimatedMatches();
console.log(`Found ${matchCount} total suggestions for "${query}"`);

// Get the first 10 results
const results = suggestionSearch.getResults(0, 10);
console.log("First 10 suggestion results:");
for (let i = 0; i < results.size(); i++) {
    const entry = results.get(i);
    console.log(`  ${i}: ${entry.getTitle()} (${entry.getPath()})`);
}

// Get more results with pagination
if (matchCount > 10) {
    const moreResults = suggestionSearch.getResults(10, 10); // Next 10 results
    console.log("Next 10 suggestion results:");
    for (let i = 0; i < moreResults.size(); i++) {
        const entry = moreResults.get(i);
        console.log(`  ${i + 10}: ${entry.getTitle()} (${entry.getPath()})`);
    }
}

// COMPARISON: Both approaches can be used together
console.log("\n=== Comparison with Full-text Search ===");

// Full-text search (existing functionality)
const searchResults = Module.search(query, 5);
console.log(`Full-text search found ${searchResults.size()} results`);

// Suggestion search (new functionality)  
const suggestionResults = Module.suggest(query, 5);
console.log(`Suggestion search found ${suggestionResults.size()} results`);

// Compare the results
console.log("Full-text search results:");
for (let i = 0; i < searchResults.size(); i++) {
    const entry = searchResults.get(i);
    console.log(`  ${entry.getTitle()} (${entry.getPath()})`);
}

console.log("Suggestion search results:");
for (let i = 0; i < suggestionResults.size(); i++) {
    const entry = suggestionResults.get(i);
    console.log(`  ${entry.getTitle()} (${entry.getPath()})`);
}

// PRACTICAL EXAMPLE: Building a search dropdown
console.log("\n=== Practical Example: Search Dropdown ===");

function buildSearchDropdown(userInput) {
    if (userInput.length < 2) return []; // Don't search for very short queries
    
    try {
        // Get quick suggestions (usually faster than full-text search)
        const suggestions = Module.suggest(userInput, 8);
        const dropdownItems = [];
        
        for (let i = 0; i < suggestions.size(); i++) {
            const entry = suggestions.get(i);
            dropdownItems.push({
                title: entry.getTitle(),
                path: entry.getPath(),
                type: 'suggestion'
            });
        }
        
        return dropdownItems;
    } catch (error) {
        console.error("Error getting suggestions:", error);
        return [];
    }
}

// Example usage
const userInput = "wik";
const dropdownItems = buildSearchDropdown(userInput);
console.log(`Dropdown for "${userInput}":`, dropdownItems);