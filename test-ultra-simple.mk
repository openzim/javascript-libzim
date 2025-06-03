#!/usr/bin/make -f

# Ultra-simple surgical fix - just handle the one problematic line
# Run with: make -f test-ultra-simple.mk

all: test-ultra-simple

test-ultra-simple:
	@echo "=== Downloading fresh libzim 9.3.0 ==="
	rm -rf libzim-9.3.0 9.3.0.tar.gz
	wget -q https://github.com/openzim/libzim/archive/9.3.0.tar.gz
	tar -xzf 9.3.0.tar.gz
	
	@echo "=== APPLYING ULTRA-SIMPLE PATCHES ==="
	
	# SEARCH.CPP - Just fix the one problematic line, leave everything else alone
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/try { m_stemmer = Xapian::Stem(languageLocale.getLanguage()); } catch (...) { m_stemmer = Xapian::Stem("none"); }/' libzim-9.3.0/src/search.cpp
	
	# SUGGESTION.CPP - Just fix the one problematic line, leave everything else alone  
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/try { m_stemmer = Xapian::Stem(languageLocale.getLanguage()); } catch (...) { m_stemmer = Xapian::Stem("none"); }/' libzim-9.3.0/src/suggestion.cpp
	
	@echo "=== VERIFICATION ==="
	@echo "search.cpp - Stemmer line replaced: $$(grep -c 'try { m_stemmer = Xapian::Stem' libzim-9.3.0/src/search.cpp || echo '0')"
	@echo "suggestion.cpp - Stemmer line replaced: $$(grep -c 'try { m_stemmer = Xapian::Stem' libzim-9.3.0/src/suggestion.cpp || echo '0')"
	@echo ""
	@echo "=== SUCCESS! Ultra-simple patches applied ==="

clean:
	rm -rf libzim-9.3.0 9.3.0.tar.gz

.PHONY: all test-ultra-simple clean