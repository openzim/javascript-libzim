#!/usr/bin/make -f

# Ultimate debugging - show us what language is causing the crash
# Run with: make -f ultimate-debug.mk

all: ultimate-debug

ultimate-debug:
	@echo "=== Downloading fresh libzim 9.3.0 ==="
	rm -rf libzim-9.3.0 9.3.0.tar.gz
	wget -q https://github.com/openzim/libzim/archive/9.3.0.tar.gz
	tar -xzf 9.3.0.tar.gz
	
	@echo "=== APPLYING ULTIMATE DEBUG PATCHES ==="
	
	# SEARCH.CPP - Show us everything about the language
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/{ std::string stemLang = languageLocale.getLanguage(); std::cout << "=== STEMMER DEBUG ===" << std::endl; std::cout << "Language from locale: [" << stemLang << "]" << std::endl; std::cout << "Length: " << stemLang.length() << std::endl; for (size_t i = 0; i < stemLang.length(); ++i) { std::cout << "Char " << i << ": " << (int)stemLang[i] << " (" << stemLang[i] << ")" << std::endl; } if (stemLang == "af" || stemLang == "afr" || stemLang.empty()) { std::cout << "Using none stemmer for: [" << stemLang << "]" << std::endl; m_stemmer = Xapian::Stem("none"); } else { std::cout << "Creating stemmer for: [" << stemLang << "]" << std::endl; m_stemmer = Xapian::Stem(stemLang); } std::cout << "=== END STEMMER DEBUG ===" << std::endl; }/' libzim-9.3.0/src/search.cpp
	
	# SUGGESTION.CPP - Show us everything about the language  
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/{ std::string stemLang = languageLocale.getLanguage(); std::cout << "=== SUGGESTION STEMMER DEBUG ===" << std::endl; std::cout << "Language from locale: [" << stemLang << "]" << std::endl; std::cout << "Length: " << stemLang.length() << std::endl; for (size_t i = 0; i < stemLang.length(); ++i) { std::cout << "Char " << i << ": " << (int)stemLang[i] << " (" << stemLang[i] << ")" << std::endl; } if (stemLang == "af" || stemLang == "afr" || stemLang.empty()) { std::cout << "Using none stemmer for: [" << stemLang << "]" << std::endl; m_stemmer = Xapian::Stem("none"); } else { std::cout << "Creating stemmer for: [" << stemLang << "]" << std::endl; m_stemmer = Xapian::Stem(stemLang); } std::cout << "=== END SUGGESTION STEMMER DEBUG ===" << std::endl; }/' libzim-9.3.0/src/suggestion.cpp
	
	@echo "=== VERIFICATION ==="
	@echo "search.cpp - Ultimate debug added: $$(grep -c 'STEMMER DEBUG' libzim-9.3.0/src/search.cpp || echo '0')"
	@echo "suggestion.cpp - Ultimate debug added: $$(grep -c 'SUGGESTION STEMMER DEBUG' libzim-9.3.0/src/suggestion.cpp || echo '0')"

clean:
	rm -rf libzim-9.3.0 9.3.0.tar.gz

.PHONY: all ultimate-debug clean