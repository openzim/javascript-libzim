// JavaScript usage examples for Search functionality in javascript-libzim
// This demonstrates both basic search and enhanced search with snippets
// Usage: Include this after loading the libzim WASM module and archive

// First, load an archive
Module.loadArchive("path/to/your/file.zim");

console.log("=== JavaScript-libzim Search Usage Examples ===");

// BASIC SEARCH (Existing functionality)
console.log("\n=== 1. Basic Full-Text Search ===");

const query = "ray";
const maxResults = 10;

// Basic search returns only paths
const searchResults = Module.search(query, maxResults);
console.log(`Basic search found ${searchResults.size()} results for "${query}"`);

// Iterate through basic search results
for (let i = 0; i < searchResults.size(); i++) {
    const entry = searchResults.get(i);
    console.log(`${i}: ${entry.getTitle()} (${entry.getPath()})`);
    
    // You can get the full content if needed
    const item = entry.getItem(true); // true = follow redirects
    console.log(`   MIME type: ${item.getMimetype()}`);
}

// ENHANCED SEARCH WITH SNIPPETS (New functionality - NOW WORKING!)
console.log("\n=== 2. Enhanced Search with Content Snippets ===");

// Enhanced search returns SearchIteratorWrapper objects with snippets
const snippetResults = Module.searchWithSnippets(query, maxResults);
console.log(`Enhanced search found ${snippetResults.size()} results with snippets for "${query}"`);

// Iterate through enhanced search results
for (let i = 0; i < snippetResults.size(); i++) {
    const result = snippetResults.get(i);
    
    console.log(`\n--- Result ${i} ---`);
    console.log(`Title: ${result.getTitle()}`);
    console.log(`Path: ${result.getPath()}`);
    console.log(`Score: ${result.getScore()}`);
    console.log(`Word Count: ${result.getWordCount()}`);
    console.log(`Snippet: ${result.getSnippet()}`);
    
    // You can still get the full entry if needed
    const entry = result.getEntry();
    console.log(`Full title: ${entry.getTitle()}`);
}

// COMPARISON: Basic vs Enhanced Search
console.log("\n=== 3. Comparison: Basic vs Enhanced ===");

console.log("Basic search results (paths only):");
const basicResults = Module.search("ray charles", 3);
for (let i = 0; i < basicResults.size(); i++) {
    const entry = basicResults.get(i);
    console.log(`  ${entry.getPath()}`);
}

console.log("\nEnhanced search results (with snippets):");
const enhancedResults = Module.searchWithSnippets("ray charles", 3);
for (let i = 0; i < enhancedResults.size(); i++) {
    const result = enhancedResults.get(i);
    console.log(`  ${result.getPath()}`);
    console.log(`    Score: ${result.getScore()}, Words: ${result.getWordCount()}`);
    console.log(`    Snippet: ${result.getSnippet().substring(0, 100)}...`);
}

// PRACTICAL EXAMPLE: Building a Search Results Page
console.log("\n=== 4. Practical Example: Search Results Page ===");

function performAdvancedSearch(searchQuery, resultCount = 20) {
    console.log(`\nPerforming advanced search for: "${searchQuery}"`);
    
    try {
        const results = Module.searchWithSnippets(searchQuery, resultCount);
        const searchData = [];
        
        for (let i = 0; i < results.size(); i++) {
            const result = results.get(i);
            
            searchData.push({
                title: result.getTitle(),
                path: result.getPath(),
                snippet: result.getSnippet(),
                score: result.getScore(),
                wordCount: result.getWordCount(),
                relevance: calculateRelevance(result.getScore(), result.getWordCount())
            });
        }
        
        // Sort by relevance (score is already quite good, but you can customize)
        searchData.sort((a, b) => b.score - a.score);
        
        return {
            query: searchQuery,
            totalResults: searchData.length,
            results: searchData
        };
        
    } catch (error) {
        console.error("Error performing search:", error);
        return {
            query: searchQuery,
            totalResults: 0,
            results: [],
            error: error.message
        };
    }
}

function calculateRelevance(score, wordCount) {
    // Simple relevance calculation - you can customize this
    // Higher score is better, longer articles might be more comprehensive
    return score + (Math.log10(wordCount || 1) * 2);
}

// Example usage
const searchData = performAdvancedSearch("music piano", 5);
console.log(`\nSearch Results for "${searchData.query}":`);
console.log(`Found ${searchData.totalResults} results\n`);

searchData.results.forEach((result, index) => {
    console.log(`${index + 1}. ${result.title}`);
    console.log(`   Path: ${result.path}`);
    console.log(`   Score: ${result.score} | Words: ${result.wordCount} | Relevance: ${result.relevance.toFixed(2)}`);
    console.log(`   Snippet: ${result.snippet.substring(0, 150)}...`);
    console.log("");
});

// EXAMPLE: Search with Error Handling and Pagination
console.log("\n=== 5. Advanced Example: Pagination and Error Handling ===");

class SearchManager {
    constructor() {
        this.pageSize = 10;
        this.currentQuery = "";
        this.allResults = [];
    }
    
    search(query, pageSize = 10) {
        this.currentQuery = query;
        this.pageSize = pageSize;
        
        try {
            // Get more results than needed for pagination
            const results = Module.searchWithSnippets(query, pageSize * 5);
            this.allResults = [];
            
            for (let i = 0; i < results.size(); i++) {
                const result = results.get(i);
                this.allResults.push({
                    title: result.getTitle(),
                    path: result.getPath(),
                    snippet: result.getSnippet(),
                    score: result.getScore(),
                    wordCount: result.getWordCount()
                });
            }
            
            console.log(`Found ${this.allResults.length} total results for "${query}"`);
            return this.getPage(0);
            
        } catch (error) {
            console.error("Search failed:", error);
            return {
                query: query,
                page: 0,
                totalPages: 0,
                totalResults: 0,
                results: [],
                error: error.message
            };
        }
    }
    
    getPage(pageNumber) {
        const startIndex = pageNumber * this.pageSize;
        const endIndex = Math.min(startIndex + this.pageSize, this.allResults.length);
        const pageResults = this.allResults.slice(startIndex, endIndex);
        
        return {
            query: this.currentQuery,
            page: pageNumber,
            totalPages: Math.ceil(this.allResults.length / this.pageSize),
            totalResults: this.allResults.length,
            results: pageResults,
            hasNextPage: endIndex < this.allResults.length,
            hasPreviousPage: pageNumber > 0
        };
    }
    
    nextPage(currentPage) {
        return this.getPage(currentPage + 1);
    }
    
    previousPage(currentPage) {
        return this.getPage(Math.max(0, currentPage - 1));
    }
}

// Example usage of SearchManager
const searchManager = new SearchManager();

// Perform search
const firstPage = searchManager.search("wikipedia", 5);
console.log(`\nPage ${firstPage.page + 1} of ${firstPage.totalPages} (${firstPage.totalResults} total results):`);

firstPage.results.forEach((result, index) => {
    const globalIndex = firstPage.page * 5 + index + 1;
    console.log(`${globalIndex}. ${result.title} (Score: ${result.score})`);
    console.log(`   ${result.snippet.substring(0, 80)}...`);
});

// Get next page if available
if (firstPage.hasNextPage) {
    const secondPage = searchManager.nextPage(firstPage.page);
    console.log(`\nNext page (${secondPage.page + 1} of ${secondPage.totalPages}):`);
    
    secondPage.results.forEach((result, index) => {
        const globalIndex = secondPage.page * 5 + index + 1;
        console.log(`${globalIndex}. ${result.title} (Score: ${result.score})`);
    });
}

// EXAMPLE: Integration with Web Worker (for use in browsers)
console.log("\n=== 6. Web Worker Integration Example ===");

// This shows how to use the search functionality from a web worker
function searchInWorker(query, maxResults = 20) {
    // This would be sent to a web worker
    const workerMessage = {
        action: "searchWithSnippets",
        text: query,
        numResults: maxResults
    };
    
    console.log("Message to send to worker:", workerMessage);
    
    // Simulated worker response processing
    function processWorkerResponse(response) {
        if (response.error) {
            console.error("Worker search failed:", response.error);
            return [];
        }
        
        console.log(`Worker returned ${response.results.length} results`);
        
        // Process the results
        return response.results.map((result, index) => ({
            rank: index + 1,
            title: result.title,
            path: result.path,
            snippet: result.snippet,
            score: result.score,
            wordCount: result.wordCount,
            url: `#${result.path}` // For navigation
        }));
    }
    
    // Example of processing - in real usage, this would come from the worker
    try {
        const directResults = Module.searchWithSnippets(query, maxResults);
        const mockWorkerResponse = {
            results: []
        };
        
        for (let i = 0; i < directResults.size(); i++) {
            const result = directResults.get(i);
            mockWorkerResponse.results.push({
                title: result.getTitle(),
                path: result.getPath(),
                snippet: result.getSnippet(),
                score: result.getScore(),
                wordCount: result.getWordCount()
            });
        }
        
        return processWorkerResponse(mockWorkerResponse);
        
    } catch (error) {
        return processWorkerResponse({ error: error.message });
    }
}

// Test the worker integration
const workerResults = searchInWorker("music", 3);
console.log("Processed worker results:");
workerResults.forEach(result => {
    console.log(`${result.rank}. ${result.title} (${result.url})`);
    console.log(`   Score: ${result.score} | ${result.snippet.substring(0, 60)}...`);
});

console.log("\n=== End of Search Usage Examples ===");
console.log("✅ All search functionality is now working with proper snippet extraction!");
