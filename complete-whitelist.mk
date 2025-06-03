#!/usr/bin/make -f

# Complete whitelist approach with all Xapian-supported languages
# Run with: make -f complete-whitelist.mk

all: complete-whitelist

complete-whitelist:
	@echo "=== Downloading fresh libzim 9.3.0 ==="
	rm -rf libzim-9.3.0 9.3.0.tar.gz
	wget -q https://github.com/openzim/libzim/archive/9.3.0.tar.gz
	tar -xzf 9.3.0.tar.gz
	
	@echo "=== APPLYING COMPLETE WHITELIST PATCHES ==="
	
	# Add #include <set> to both files first
	sed -i '/#include <unicode\/locid.h>/a #include <set>' libzim-9.3.0/src/search.cpp
	sed -i '/#include <unicode\/locid.h>/a #include <set>' libzim-9.3.0/src/suggestion.cpp
	
	# SEARCH.CPP - Complete list of all Xapian-supported languages
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/{ std::string stemLang = languageLocale.getLanguage(); static const std::set<std::string> supportedLangs = {"ar", "hy", "eu", "ca", "da", "nl", "en", "fi", "fr", "de", "el", "hi", "hu", "id", "ga", "it", "lt", "ne", "no", "pt", "ro", "ru", "sr", "es", "sv", "tr"}; if (supportedLangs.find(stemLang) != supportedLangs.end()) { m_stemmer = Xapian::Stem(stemLang); } else { m_stemmer = Xapian::Stem("none"); } }/' libzim-9.3.0/src/search.cpp
	
	# SUGGESTION.CPP - Complete list of all Xapian-supported languages
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/{ std::string stemLang = languageLocale.getLanguage(); static const std::set<std::string> supportedLangs = {"ar", "hy", "eu", "ca", "da", "nl", "en", "fi", "fr", "de", "el", "hi", "hu", "id", "ga", "it", "lt", "ne", "no", "pt", "ro", "ru", "sr", "es", "sv", "tr"}; if (supportedLangs.find(stemLang) != supportedLangs.end()) { m_stemmer = Xapian::Stem(stemLang); } else { m_stemmer = Xapian::Stem("none"); } }/' libzim-9.3.0/src/suggestion.cpp
	
	@echo "=== VERIFICATION ==="
	@echo "search.cpp - Include added: $$(grep -c '#include <set>' libzim-9.3.0/src/search.cpp || echo '0')"
	@echo "suggestion.cpp - Include added: $$(grep -c '#include <set>' libzim-9.3.0/src/suggestion.cpp || echo '0')"
	@echo "search.cpp - Complete whitelist added: $$(grep -c 'supportedLangs' libzim-9.3.0/src/search.cpp || echo '0')"
	@echo "suggestion.cpp - Complete whitelist added: $$(grep -c 'supportedLangs' libzim-9.3.0/src/suggestion.cpp || echo '0')"
	@echo ""
	@echo "Supported languages: ar, hy, eu, ca, da, nl, en, fi, fr, de, el, hi, hu, id, ga, it, lt, ne, no, pt, ro, ru, sr, es, sv, tr"
	@echo "All other languages will use 'none' stemmer"

clean:
	rm -rf libzim-9.3.0 9.3.0.tar.gz

.PHONY: all complete-whitelist clean