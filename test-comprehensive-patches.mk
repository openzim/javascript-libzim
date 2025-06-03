#!/usr/bin/make -f

# Comprehensive test makefile to fix both search.cpp and suggestion.cpp
# Run with: make -f test-comprehensive-patches.mk

all: test-comprehensive-patches

test-comprehensive-patches:
	@echo "=== Downloading fresh libzim 9.3.0 ==="
	rm -rf libzim-9.3.0 9.3.0.tar.gz
	wget -q https://github.com/openzim/libzim/archive/9.3.0.tar.gz
	tar -xzf 9.3.0.tar.gz
	
	@echo "=== BEFORE PATCHING ==="
	@echo "search.cpp - Original language line:"
	grep -n "database.get_metadata(\"language\")" libzim-9.3.0/src/search.cpp || echo "Not found"
	@echo "search.cpp - Original catch block:"
	grep -n -A1 "No stemming for language" libzim-9.3.0/src/search.cpp || echo "Not found"
	@echo ""
	@echo "suggestion.cpp - Original language line:"
	grep -n "database.get_metadata(\"language\")" libzim-9.3.0/src/suggestion.cpp || echo "Not found"
	@echo "suggestion.cpp - Original catch block:"
	grep -n -A1 "No stemming for language" libzim-9.3.0/src/suggestion.cpp || echo "Not found"
	@echo ""
	
	@echo "=== APPLYING SEARCH.CPP PATCHES ==="
	# Fix search.cpp language metadata trimming
	sed -i '/auto language = database.get_metadata("language");/a\
                /* DEBUG: Log what we get from ZIM metadata */\
                std::cout << "DEBUG: Raw language from database metadata: \\"" << language << "\\"" << std::endl;\
                /* Trim whitespace from language metadata to avoid Xapian stemming errors */\
                if (!language.empty()) {\
                    language.erase(0, language.find_first_not_of(" \\t\\n\\r\\f\\v"));\
                    language.erase(language.find_last_not_of(" \\t\\n\\r\\f\\v") + 1);\
                }\
                std::cout << "DEBUG: Language after trimming: \\"" << language << "\\"" << std::endl;' libzim-9.3.0/src/search.cpp
	
	# Fix search.cpp fallback language trimming
	sed -i '/language = archive.getMetadata("Language");/a\
                        std::cout << "DEBUG: Fallback language from archive metadata: \\"" << language << "\\"" << std::endl;\
                        /* Also trim the fallback language metadata */\
                        if (!language.empty()) {\
                            language.erase(0, language.find_first_not_of(" \\t\\n\\r\\f\\v"));\
                            language.erase(language.find_last_not_of(" \\t\\n\\r\\f\\v") + 1);\
                        }\
                        std::cout << "DEBUG: Fallback language after trimming: \\"" << language << "\\"" << std::endl;' libzim-9.3.0/src/search.cpp
	
	# Fix search.cpp ICU debug
	sed -i '/icu::Locale languageLocale(language.c_str());/a\
                    std::cout << "DEBUG: ICU getLanguage() result: \\"" << languageLocale.getLanguage() << "\\"" << std::endl;\
                    std::cout << "DEBUG: ICU getName() result: \\"" << languageLocale.getName() << "\\"" << std::endl;' libzim-9.3.0/src/search.cpp
	
	# Fix search.cpp stemmer debug
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/std::string stemLanguage = languageLocale.getLanguage();\
                        std::cout << "DEBUG: About to create Xapian::Stem with: \\"" << stemLanguage << "\\"" << std::endl;\
                        m_stemmer = Xapian::Stem(stemLanguage);\
                        std::cout << "DEBUG: Xapian::Stem created successfully" << std::endl;/' libzim-9.3.0/src/search.cpp
	
	# Fix search.cpp stemmer fallback - PROPER VERSION with line breaks
	sed -i 's/std::cout << "No stemming for language .*/std::cout << "DEBUG: Stemmer failed for language: \\"" << languageLocale.getLanguage() << "\\", using fallback" << std::endl;\
                        m_stemmer = Xapian::Stem("none");\
                        m_queryParser.set_stemmer(m_stemmer);/' libzim-9.3.0/src/search.cpp
	
	@echo "=== APPLYING SUGGESTION.CPP PATCHES ==="
	# Fix suggestion.cpp language metadata trimming
	sed -i '/auto language = database.get_metadata("language");/a\
  /* DEBUG: Log what we get from ZIM metadata */\
  std::cout << "DEBUG: [SUGGESTION] Raw language from database metadata: \\"" << language << "\\"" << std::endl;\
  /* Trim whitespace from language metadata to avoid Xapian stemming errors */\
  if (!language.empty()) {\
      language.erase(0, language.find_first_not_of(" \\t\\n\\r\\f\\v"));\
      language.erase(language.find_last_not_of(" \\t\\n\\r\\f\\v") + 1);\
  }\
  std::cout << "DEBUG: [SUGGESTION] Language after trimming: \\"" << language << "\\"" << std::endl;' libzim-9.3.0/src/suggestion.cpp
	
	# Fix suggestion.cpp fallback language trimming
	sed -i '/language = m_archive.getMetadata("Language");/a\
          std::cout << "DEBUG: [SUGGESTION] Fallback language from archive metadata: \\"" << language << "\\"" << std::endl;\
          /* Also trim the fallback language metadata */\
          if (!language.empty()) {\
              language.erase(0, language.find_first_not_of(" \\t\\n\\r\\f\\v"));\
              language.erase(language.find_last_not_of(" \\t\\n\\r\\f\\v") + 1);\
          }\
          std::cout << "DEBUG: [SUGGESTION] Fallback language after trimming: \\"" << language << "\\"" << std::endl;' libzim-9.3.0/src/suggestion.cpp
	
	# Fix suggestion.cpp ICU debug
	sed -i '/icu::Locale languageLocale(language.c_str());/a\
      std::cout << "DEBUG: [SUGGESTION] ICU getLanguage() result: \\"" << languageLocale.getLanguage() << "\\"" << std::endl;\
      std::cout << "DEBUG: [SUGGESTION] ICU getName() result: \\"" << languageLocale.getName() << "\\"" << std::endl;' libzim-9.3.0/src/suggestion.cpp
	
	# Fix suggestion.cpp stemmer debug
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/std::string stemLanguage = languageLocale.getLanguage();\
          std::cout << "DEBUG: [SUGGESTION] About to create Xapian::Stem with: \\"" << stemLanguage << "\\"" << std::endl;\
          m_stemmer = Xapian::Stem(stemLanguage);\
          std::cout << "DEBUG: [SUGGESTION] Xapian::Stem created successfully" << std::endl;/' libzim-9.3.0/src/suggestion.cpp
	
	# Fix suggestion.cpp stemmer fallback - Add proper fallback
	sed -i 's/std::cout << "No stemming for language .*/std::cout << "DEBUG: [SUGGESTION] Stemmer failed for language: \\"" << languageLocale.getLanguage() << "\\", using fallback" << std::endl;\
          m_stemmer = Xapian::Stem("none");\
          m_queryParser.set_stemmer(m_stemmer);/' libzim-9.3.0/src/suggestion.cpp
	
	@echo "=== VERIFICATION ==="
	@echo "search.cpp - Patched language handling:"
	grep -n -A8 "auto language = database.get_metadata" libzim-9.3.0/src/search.cpp | head -15
	@echo ""
	@echo "search.cpp - Patched catch block:"
	grep -n -A3 "DEBUG: Stemmer failed" libzim-9.3.0/src/search.cpp
	@echo ""
	@echo "suggestion.cpp - Patched language handling:"
	grep -n -A8 "auto language = database.get_metadata" libzim-9.3.0/src/suggestion.cpp | head -15
	@echo ""
	@echo "suggestion.cpp - Patched catch block:"
	grep -n -A3 "DEBUG.*SUGGESTION.*Stemmer failed" libzim-9.3.0/src/suggestion.cpp
	@echo ""
	@echo "Total DEBUG lines in search.cpp:"
	grep -c "DEBUG:" libzim-9.3.0/src/search.cpp || echo "0"
	@echo "Total DEBUG lines in suggestion.cpp:"
	grep -c "DEBUG:" libzim-9.3.0/src/suggestion.cpp || echo "0"
	@echo ""
	@echo "=== SUCCESS! Comprehensive patches applied to both files ==="

clean:
	rm -rf libzim-9.3.0 9.3.0.tar.gz

.PHONY: all test-comprehensive-patches clean