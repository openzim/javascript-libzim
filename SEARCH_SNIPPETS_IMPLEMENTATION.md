# Search Snippets Implementation

## 🎯 Overview

This document explains the implementation of **content snippets** for search results in javascript-libzim. Content snippets provide contextual text excerpts around search terms, similar to Google search results and Kiwix Desktop functionality.

The implementation extends libzim's full-text search capabilities to extract and highlight relevant content from Wikipedia articles and other ZIM file content.

## 🏗️ Architecture

The snippets system operates on three levels of search functionality:

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Suggestions   │    │   Basic Search   │    │ Enhanced Search │
│  (Autocomplete) │    │   (Paths only)   │    │ (With Snippets) │
├─────────────────┤    ├──────────────────┤    ├─────────────────┤
│ SuggestionAPI   │    │ Searcher + Query │    │ SearchIterator  │
│ Fast title      │    │ Entry paths      │    │ Content snippets│
│ highlighting    │    │ No snippets      │    │ Scores & stats  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
       ↓                       ↓                       ↓
   Dropdown UI            Results page           Rich results page
```

### Core Components

1. **SuggestionSearcher** - Fast title-based autocomplete for dropdown suggestions
2. **Searcher** - Full-text search returning article paths for basic results
3. **SearchIterator** - Enhanced search objects with snippet extraction capabilities

## 📊 API Structure

### Enhanced Search with Snippets
```javascript
// JavaScript Web Worker API
worker.postMessage({
    action: "searchWithSnippets", 
    text: "search query",
    numResults: 20
});

// Returns rich results with content snippets
{
    results: [{
        path: "A/Article_Path",
        title: "Article Title", 
        snippet: "...contextual content with <b>highlighted</b> terms...",
        score: 95,
        wordCount: 1250
    }]
}
```

### C++ API Bindings
```cpp
// SearchIteratorWrapper provides access to libzim's SearchIterator
class SearchIteratorWrapper {
    std::string getPath() const;        // Article path
    std::string getTitle() const;       // Article title
    std::string getSnippet() const;     // Content snippet with highlighting
    int getScore() const;               // Search relevance score
    int getWordCount() const;           // Article word count
    EntryWrapper getEntry() const;      // Full Entry object
};

// Main search function
std::vector<SearchIteratorWrapper> searchWithSnippets(std::string text, int numResults);
```

## 🔧 Implementation Details

### 1. SearchIterator Integration

The core of snippet functionality comes from libzim's `zim::SearchIterator` class, which provides a `getSnippet()` method that:

- Extracts HTML content from ZIM entries
- Parses HTML to plain text using `MyHtmlParser`
- Uses Xapian's snippet generation to find relevant passages
- Highlights search terms with HTML `<b>` tags
- Returns contextual excerpts (~500 characters)

### 2. WASM Exception Handling

A critical implementation challenge was handling libzim's HTML parser exceptions in the WASM environment:

**The Problem:**
```cpp
// libzim's MyHtmlParser uses exceptions for control flow
if (closing_tag && tag == "body") {
    throw true;  // Normal control flow, not an error
}
```

**The Solution:**
The HTML parser patch in `myhtmlparse.cc` replaces control flow exceptions with returns:
```cpp
// Makefile patch applied during build
sed -i 's/throw true;/return;/g' libzim-9.3.0/src/xapian/myhtmlparse.cc
sed -i 's/throw newcharset;/return;/g' libzim-9.3.0/src/xapian/myhtmlparse.cc
```

This eliminates WASM exception handling issues while preserving the parser's logic.

### 3. Language Stemming Safety

The implementation includes safeguards for Xapian's language stemming:

```cpp
// Whitelist approach prevents unsupported language exceptions
std::string stemLang = languageLocale.getLanguage();
static const std::set<std::string> supportedLangs = {
    "ar", "hy", "eu", "ca", "da", "nl", "en", "fi", "fr", "de", 
    "el", "hi", "hu", "id", "ga", "it", "lt", "ne", "no", "pt", 
    "ro", "ru", "sr", "es", "sv", "tr"
};

if (supportedLangs.find(stemLang) != supportedLangs.end()) {
    m_stemmer = Xapian::Stem(stemLang);
} else {
    m_stemmer = Xapian::Stem("none");  // Safe fallback
}
```

This prevents exceptions when encountering unsupported languages in ZIM files.

## 📁 File Structure

### Core Implementation Files

**`libzim_bindings.cpp`** - C++ Emscripten bindings
- `SearchIteratorWrapper` class implementation
- `searchWithSnippets()` function 
- Exception handling for snippet extraction
- Emscripten binding declarations

**`prejs_file_api.js`** - Web Worker JavaScript interface
- `searchWithSnippets` message handler
- Result formatting and error handling
- Integration with existing search API

**`Makefile`** - Build configuration
- libzim source patching for WASM compatibility
- HTML parser exception removal
- Language stemming whitelist application

### Testing and Examples

**`tests/prototype/index.html`** - Interactive test interface
- Live snippet extraction testing
- Debug functionality for troubleshooting
- Comparative display of different search types

**`javascript_search_usage_example.js`** - Comprehensive usage examples
- Basic and enhanced search patterns
- Error handling best practices
- Pagination and result management
- Web Worker integration patterns

## 🔄 Snippet Generation Process

1. **Query Processing**
   - User query parsed and stemmed by Xapian
   - Full-text index searched for matching documents

2. **Content Extraction**
   - HTML content retrieved from ZIM entries
   - `MyHtmlParser` converts HTML to plain text
   - Text normalized and cleaned

3. **Snippet Creation**
   - Xapian's `snippet()` method finds relevant passages
   - Search terms highlighted with `<b>` tags
   - Content truncated to ~500 characters around matches

4. **Result Packaging**
   - Snippets combined with metadata (score, word count)
   - Results sorted by relevance
   - Returned as structured JavaScript objects

## 🛠️ Build Process

The implementation requires patching libzim source during compilation:

```bash
# Essential patches applied by Makefile
# 1. Add required headers
sed -i '/#include <unicode\/locid.h>/a #include <set>' libzim-*/src/search.cpp

# 2. Apply language whitelist for stemming safety  
sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/[whitelist_code]/' libzim-*/src/search.cpp

# 3. Fix HTML parser exceptions for WASM compatibility
sed -i 's/throw true;/return;/g' libzim-9.3.0/src/xapian/myhtmlparse.cc
```

## 📚 Usage Examples

### Simple Snippet Search
```javascript
// Basic snippet search
const results = Module.searchWithSnippets("music piano", 10);
for (let i = 0; i < results.size(); i++) {
    const result = results.get(i);
    console.log(`${result.getTitle()}: ${result.getSnippet()}`);
}
```

### Advanced Result Processing
```javascript
// Web Worker integration
worker.postMessage({
    action: "searchWithSnippets",
    text: "quantum physics",
    numResults: 20
});

worker.onmessage = function(event) {
    const searchData = event.data;
    searchData.results.forEach(result => {
        displaySearchResult({
            title: result.title,
            snippet: result.snippet,
            url: `#${result.path}`,
            score: result.score
        });
    });
};
```

## 🎯 Key Benefits

- **Rich Content Preview** - Users see relevant content before clicking
- **Search Term Highlighting** - Important terms emphasized in results
- **Relevance Scoring** - Results ranked by importance and match quality
- **Performance** - Efficient extraction without loading full articles
- **Compatibility** - Works with existing ZIM files and search infrastructure

## 🔍 Technical Insights

### Exception Handling Strategy
Rather than catching exceptions after they occur, the implementation **prevents** problematic exceptions by:
- Modifying control flow in HTML parser (replace `throw` with `return`)
- Using language whitelists to avoid unsupported stemmer calls
- Providing graceful fallbacks for edge cases

### WASM Optimization
The solution prioritizes WASM compatibility by:
- Eliminating problematic control-flow exceptions
- Using minimal memory allocation for snippet generation
- Maintaining synchronous operation for Web Worker integration

### Backward Compatibility
The implementation preserves all existing functionality:
- Basic search API unchanged
- Suggestion API unmodified  
- Entry and Item wrappers remain compatible
- No breaking changes to existing applications

This architecture enables rich search experiences while maintaining the performance and compatibility characteristics of the original javascript-libzim implementation.
