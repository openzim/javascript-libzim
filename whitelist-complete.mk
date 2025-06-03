#!/usr/bin/make -f

# Whitelist approach with proper headers
# Run with: make -f whitelist-complete.mk

all: whitelist-complete

whitelist-complete:
	@echo "=== Downloading fresh libzim 9.3.0 ==="
	rm -rf libzim-9.3.0 9.3.0.tar.gz
	wget -q https://github.com/openzim/libzim/archive/9.3.0.tar.gz
	tar -xzf 9.3.0.tar.gz
	
	@echo "=== APPLYING WHITELIST PATCHES ==="
	
	# Add #include <set> to both files first
	sed -i '/#include <unicode\/locid.h>/a #include <set>' libzim-9.3.0/src/search.cpp
	sed -i '/#include <unicode\/locid.h>/a #include <set>' libzim-9.3.0/src/suggestion.cpp
	
	# SEARCH.CPP - Only allow known supported languages
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/{ std::string stemLang = languageLocale.getLanguage(); static const std::set<std::string> supportedLangs = {"da", "nl", "en", "fi", "fr", "de", "hu", "it", "no", "pt", "ro", "ru", "es", "sv", "tr"}; if (supportedLangs.find(stemLang) != supportedLangs.end()) { m_stemmer = Xapian::Stem(stemLang); } else { m_stemmer = Xapian::Stem("none"); } }/' libzim-9.3.0/src/search.cpp
	
	# SUGGESTION.CPP - Only allow known supported languages
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/{ std::string stemLang = languageLocale.getLanguage(); static const std::set<std::string> supportedLangs = {"da", "nl", "en", "fi", "fr", "de", "hu", "it", "no", "pt", "ro", "ru", "es", "sv", "tr"}; if (supportedLangs.find(stemLang) != supportedLangs.end()) { m_stemmer = Xapian::Stem(stemLang); } else { m_stemmer = Xapian::Stem("none"); } }/' libzim-9.3.0/src/suggestion.cpp
	
	@echo "=== VERIFICATION ==="
	@echo "search.cpp - Include added: $$(grep -c '#include <set>' libzim-9.3.0/src/search.cpp || echo '0')"
	@echo "suggestion.cpp - Include added: $$(grep -c '#include <set>' libzim-9.3.0/src/suggestion.cpp || echo '0')"
	@echo "search.cpp - Whitelist added: $$(grep -c 'supportedLangs' libzim-9.3.0/src/search.cpp || echo '0')"
	@echo "suggestion.cpp - Whitelist added: $$(grep -c 'supportedLangs' libzim-9.3.0/src/suggestion.cpp || echo '0')"

clean:
	rm -rf libzim-9.3.0 9.3.0.tar.gz

.PHONY: all whitelist-complete clean