#include <zim/archive.h>
#include <zim/item.h>
#include <zim/error.h>
#include <zim/search.h>
#include <zim/suggestion.h>
#include <iostream>
#include <chrono>
#include <emscripten/bind.h>
#include <emscripten/emscripten.h>
#include <emscripten/val.h>

using namespace emscripten;

std::shared_ptr<zim::Archive> g_archive;

int main(int argc, char* argv[])
{
    std::cout << "assembler initialized" << std::endl;
    return 0;
}

void loadArchive(std::string filename) {
    g_archive.reset(new zim::Archive(filename));
    std::cout << "archive loaded" << std::endl;
}

// Get article count of a ZIM file
unsigned int getArticleCount() {
    return g_archive->getArticleCount();
}

class BlobWrapper{
public:
    BlobWrapper(zim::Blob blob):
        m_blob(blob)
    { }

    val getContent() const {
      return val(typed_memory_view(m_blob.size(), m_blob.data()));
    }

private:
    zim::Blob m_blob;
};

class ItemWrapper{
public:
    ItemWrapper(zim::Item item):
        m_item(item)
    { }

    BlobWrapper getData() const {
      return BlobWrapper(m_item.getData());
    }
    std::string getMimetype() const { return m_item.getMimetype(); }

private:
    zim::Item m_item;
};

class EntryWrapper{
public:
    EntryWrapper(zim::Entry entry):
        m_entry(entry)
    { }

    ItemWrapper getItem(bool follow) {
        return ItemWrapper(m_entry.getItem(follow));
    }
    std::string getPath() {
        return m_entry.getPath();
    }
    std::string getTitle() {
        return m_entry.getTitle();
    }
    bool isRedirect() {
        return m_entry.isRedirect();
    }
    EntryWrapper getRedirectEntry() {
        return EntryWrapper(m_entry.getRedirectEntry());
    }

private:
    zim::Entry m_entry;
};

// SearchIterator wrapper - Clean version relying on the fixed libzim implementation
class SearchIteratorWrapper {
public:
    SearchIteratorWrapper(const zim::SearchIterator& iterator)
        : m_iterator(iterator) {}
    
    std::string getPath() const {
        return m_iterator.getPath();
    }
    
    std::string getTitle() const {
        return m_iterator.getTitle();
    }
    
    std::string getSnippet() const {
        try {
            return m_iterator.getSnippet();
        } catch (const std::exception& e) {
            // Log only actual errors, not normal operation
            std::cout << "SearchIterator::getSnippet() error: " << e.what() << std::endl;
            return "";
        } catch (...) {
            std::cout << "SearchIterator::getSnippet() unknown error" << std::endl;
            return "";
        }
    }
    
    int getScore() const {
        return m_iterator.getScore();
    }
    
    int getWordCount() const {
        return m_iterator.getWordCount();
    }
    
    EntryWrapper getEntry() const {
        return EntryWrapper(*m_iterator);
    }

private:
    zim::SearchIterator m_iterator;
};

// Forward declaration
class SuggestionSearchWrapper;

// SuggestionSearcher wrapper
class SuggestionSearcherWrapper {
public:
    SuggestionSearcherWrapper() {
        if (!g_archive) {
            throw std::runtime_error("No archive loaded");
        }
        searcher = std::make_unique<zim::SuggestionSearcher>(*g_archive);
    }
    
    SuggestionSearchWrapper suggest(const std::string& query);

private:
    std::unique_ptr<zim::SuggestionSearcher> searcher;
};

// SuggestionSearch wrapper
class SuggestionSearchWrapper {
public:
    // Use move constructor to avoid copy issues
    SuggestionSearchWrapper(zim::SuggestionSearch&& search)
        : search_(std::move(search)) {}
    
    unsigned int getEstimatedMatches() const {
        try {
            return search_.getEstimatedMatches();
        } catch (const std::exception& e) {
            std::cout << "getEstimatedMatches error: " << e.what() << std::endl;
            return 0;
        }
    }
    
    std::vector<EntryWrapper> getResults(int start, int count) const {
        try {
            zim::SuggestionResultSet resultSet = search_.getResults(start, count);
            std::vector<EntryWrapper> results;
            
            // Use the iterator to get entries
            for (auto it = resultSet.begin(); it != resultSet.end(); ++it) {
                try {
                    // Use the iterator's getEntry() method
                    zim::Entry entry = it.getEntry();
                    results.push_back(EntryWrapper(entry));
                } catch (const std::exception& e) {
                    std::cout << "Error getting entry from suggestion iterator: " << e.what() << std::endl;
                    // Skip this item and continue
                }
            }
            
            return results;
        } catch (const std::exception& e) {
            std::cout << "getResults error: " << e.what() << std::endl;
            return std::vector<EntryWrapper>();
        }
    }

private:
    zim::SuggestionSearch search_;
};

// Implement the suggest method (needs to be after SuggestionSearchWrapper definition)
SuggestionSearchWrapper SuggestionSearcherWrapper::suggest(const std::string& query) {
    try {
        // Use suggest() method
        zim::SuggestionSearch search = searcher->suggest(query);
        // Use move constructor
        return SuggestionSearchWrapper(std::move(search));
    } catch (const std::exception& e) {
        std::cout << "suggest error: " << e.what() << std::endl;
        throw;
    }
}

// Get an entry by its path
std::unique_ptr<EntryWrapper> getEntryByPath(std::string url) {
    try {
        zim::Entry entry = g_archive->getEntryByPath(url);
        return std::unique_ptr<EntryWrapper>(new EntryWrapper(entry));
    } catch(zim::EntryNotFound& e) {
        std::cout << "entry " << url << " not found" << std::endl;
        return nullptr;
    } catch(std::exception& e) {
        std::cout << "other exception : " << e.what() << std::endl;
        return nullptr;
    }
}

// Search for a text using proper Query API
std::vector<EntryWrapper> search(std::string text, int numResults) {
    try {
        auto searcher = zim::Searcher(*g_archive);
        
        // Use proper Query construction
        zim::Query query;
        query.setQuery(text);
        
        auto search = searcher.search(query);
        auto searchResultSet = search.getResults(0, numResults);
        std::vector<EntryWrapper> ret;
        for(auto entry:searchResultSet) {
            ret.push_back(EntryWrapper(entry));
        }
        return ret;
    } catch(const std::exception& e) {
        std::cout << "Search error: " << e.what() << std::endl;
        return std::vector<EntryWrapper>();
    }
}

// Enhanced search with snippets - now works properly with the libzim fix
std::vector<SearchIteratorWrapper> searchWithSnippets(std::string text, int numResults) {
    try {
        auto searcher = zim::Searcher(*g_archive);
        
        // Create query
        zim::Query query;
        query.setQuery(text);
        
        // Perform search
        auto search = searcher.search(query);
        auto searchResultSet = search.getResults(0, numResults);
        
        // Use iterator pattern like NodeJS, not range-based for loop
        std::vector<SearchIteratorWrapper> ret;
        auto it = searchResultSet.begin();
        auto end = searchResultSet.end();
        
        while (it != end) {
            // Pass the iterator object directly, like NodeJS does
            ret.push_back(SearchIteratorWrapper(it));
            ++it;
        }
        
        return ret;
    } catch(const std::exception& e) {
        std::cout << "Search with snippets error: " << e.what() << std::endl;
        return std::vector<SearchIteratorWrapper>();
    }
}

// Enhanced search with language control
std::vector<EntryWrapper> searchWithLanguage(std::string text, int numResults, std::string language = "") {
    try {
        auto searcher = zim::Searcher(*g_archive);
        zim::Query query;
        
        // Set the query text using proper API
        query.setQuery(text);
        
        // TODO: Add language control if libzim supports it
        // This might require additional Query methods or Searcher configuration
        
        auto search = searcher.search(query);
        auto searchResultSet = search.getResults(0, numResults);
        std::vector<EntryWrapper> ret;
        for(auto entry:searchResultSet) {
            ret.push_back(EntryWrapper(entry));
        }
        return ret;
    } catch(const std::exception& e) {
        std::cout << "Search with language error: " << e.what() << std::endl;
        return std::vector<EntryWrapper>();
    }
}

// Suggestion search function using proper API
std::vector<EntryWrapper> suggest(std::string text, int numResults) {
    try {
        auto suggestionSearcher = zim::SuggestionSearcher(*g_archive);
        
        // Use suggest() method
        auto suggestionSearch = suggestionSearcher.suggest(text);
        auto resultSet = suggestionSearch.getResults(0, numResults);
        std::vector<EntryWrapper> ret;
        
        // Use the iterator to get entries
        for (auto it = resultSet.begin(); it != resultSet.end(); ++it) {
            try {
                // Use the iterator's getEntry() method
                zim::Entry entry = it.getEntry();
                ret.push_back(EntryWrapper(entry));
            } catch (const std::exception& e) {
                std::cout << "Error getting entry from suggestion iterator: " << e.what() << std::endl;
                // Skip this item and continue
            }
        }
        return ret;
    } catch(const std::exception& e) {
        std::cout << "suggestion error: " << e.what() << std::endl;
        return std::vector<EntryWrapper>();
    }
}

// Binding code
EMSCRIPTEN_BINDINGS(libzim_module) {
    emscripten::function("loadArchive", &loadArchive);
    emscripten::function("getEntryByPath", &getEntryByPath);
    emscripten::function("getArticleCount", &getArticleCount);
    emscripten::function("search", &search);
    emscripten::function("searchWithSnippets", &searchWithSnippets);
    emscripten::function("searchWithLanguage", &searchWithLanguage);
    emscripten::function("suggest", &suggest);
    emscripten::register_vector<char>("vector<char>");
    emscripten::register_vector<EntryWrapper>("vector(EntryWrapper)");
    emscripten::register_vector<SearchIteratorWrapper>("vector(SearchIteratorWrapper)");
    class_<EntryWrapper>("EntryWrapper")
      .function("getItem", &EntryWrapper::getItem)
      .function("getPath", &EntryWrapper::getPath)
      .function("isRedirect", &EntryWrapper::isRedirect)
      .function("getRedirectEntry", &EntryWrapper::getRedirectEntry)
      .function("getTitle", &EntryWrapper::getTitle)
      ;
    class_<ItemWrapper>("ItemWrapper")
      .function("getData", &ItemWrapper::getData)
      .function("getMimetype", &ItemWrapper::getMimetype)
      ;
    class_<BlobWrapper>("BlobWrapper")
      .function("getContent", &BlobWrapper::getContent)
      ;
    class_<SearchIteratorWrapper>("SearchIteratorWrapper")
      .function("getPath", &SearchIteratorWrapper::getPath)
      .function("getTitle", &SearchIteratorWrapper::getTitle)
      .function("getSnippet", &SearchIteratorWrapper::getSnippet)
      .function("getScore", &SearchIteratorWrapper::getScore)
      .function("getWordCount", &SearchIteratorWrapper::getWordCount)
      .function("getEntry", &SearchIteratorWrapper::getEntry)
      ;
    class_<SuggestionSearcherWrapper>("SuggestionSearcher")
      .constructor<>()
      .function("suggest", &SuggestionSearcherWrapper::suggest)
      ;
    class_<SuggestionSearchWrapper>("SuggestionSearch")
      .function("getEstimatedMatches", &SuggestionSearchWrapper::getEstimatedMatches)
      .function("getResults", &SuggestionSearchWrapper::getResults)
      ;
}