#!/usr/bin/make -f

# Test makefile to verify libzim patches without building
# Run with: make -f test-patches.mk

all: test-patches

test-patches:
	@echo "=== Downloading libzim 9.3.0 ==="
	wget -q https://github.com/openzim/libzim/archive/9.3.0.tar.gz
	tar -xzf 9.3.0.tar.gz
	
	@echo "=== BEFORE PATCHING ==="
	@echo "Original language metadata line:"
	grep -n "database.get_metadata(\"language\")" libzim-9.3.0/src/search.cpp || echo "Not found"
	@echo "Original catch block:"
	grep -n -A1 "No stemming for language" libzim-9.3.0/src/search.cpp || echo "Not found"
	@echo ""
	
	@echo "=== APPLYING YOUR PATCHES ==="
	# Your whitespace trimming patch
	sed -i '/auto language = database.get_metadata("language");/a\
                /* DEBUG: Log what we get from ZIM metadata */\
                std::cout << "DEBUG: Raw language from database metadata: \\"" << language << "\\"" << std::endl;\
                /* Trim whitespace from language metadata to avoid Xapian stemming errors */\
                if (!language.empty()) {\
                    language.erase(0, language.find_first_not_of(" \\t\\n\\r\\f\\v"));\
                    language.erase(language.find_last_not_of(" \\t\\n\\r\\f\\v") + 1);\
                }\
                std::cout << "DEBUG: Language after trimming: \\"" << language << "\\"" << std::endl;' libzim-9.3.0/src/search.cpp
	
	# Your fallback language patch
	sed -i '/language = archive.getMetadata("Language");/a\
                        std::cout << "DEBUG: Fallback language from archive metadata: \\"" << language << "\\"" << std::endl;\
                        /* Also trim the fallback language metadata */\
                        if (!language.empty()) {\
                            language.erase(0, language.find_first_not_of(" \\t\\n\\r\\f\\v"));\
                            language.erase(language.find_last_not_of(" \\t\\n\\r\\f\\v") + 1);\
                        }\
                        std::cout << "DEBUG: Fallback language after trimming: \\"" << language << "\\"" << std::endl;' libzim-9.3.0/src/search.cpp
	
	# ICU debug patch
	sed -i '/icu::Locale languageLocale(language.c_str());/a\
                    std::cout << "DEBUG: ICU getLanguage() result: \\"" << languageLocale.getLanguage() << "\\"" << std::endl;\
                    std::cout << "DEBUG: ICU getName() result: \\"" << languageLocale.getName() << "\\"" << std::endl;' libzim-9.3.0/src/search.cpp
	
	# Stemmer debug patch
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/std::string stemLanguage = languageLocale.getLanguage();\
                        std::cout << "DEBUG: About to create Xapian::Stem with: \\"" << stemLanguage << "\\"" << std::endl;\
                        m_stemmer = Xapian::Stem(stemLanguage);\
                        std::cout << "DEBUG: Xapian::Stem created successfully" << std::endl;/' libzim-9.3.0/src/search.cpp
	
	# The new fallback stemmer patch
	sed -i 's/std::cout << "No stemming for language .*/std::cout << "DEBUG: Stemmer failed for language: \\"" << languageLocale.getLanguage() << "\\", using fallback" << std::endl;                        m_stemmer = Xapian::Stem("none");                        m_queryParser.set_stemmer(m_stemmer);/' libzim-9.3.0/src/search.cpp
	
	@echo "=== AFTER PATCHING ==="
	@echo "Patched language handling:"
	grep -n -A8 "auto language = database.get_metadata" libzim-9.3.0/src/search.cpp || echo "Not found"
	@echo ""
	@echo "Patched catch block:"
	grep -n -A3 "DEBUG: Stemmer failed" libzim-9.3.0/src/search.cpp || echo "Not found"
	@echo ""
	@echo "All DEBUG lines:"
	grep -n "DEBUG:" libzim-9.3.0/src/search.cpp | wc -l
	@echo ""
	@echo "=== SUCCESS! Patches applied correctly ==="

clean:
	rm -rf libzim-9.3.0 9.3.0.tar.gz

.PHONY: all test-patches clean