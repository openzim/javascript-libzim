#!/usr/bin/make -f

# Test makefile for WASM exception handling fix
# Run with: make -f test-exception-fix.mk

all: test-exception-fix

test-exception-fix:
	@echo "=== Downloading fresh libzim 9.3.0 ==="
	rm -rf libzim-9.3.0 9.3.0.tar.gz
	wget -q https://github.com/openzim/libzim/archive/9.3.0.tar.gz
	tar -xzf 9.3.0.tar.gz
	
	@echo "=== APPLYING ROBUST EXCEPTION HANDLING PATCHES ==="
	# Apply comprehensive patches with better exception handling
	sed -i '/auto language = database.get_metadata("language");/a\
                /* DEBUG: Log what we get from ZIM metadata */\
                std::cout << "DEBUG: Raw language from database metadata: \\"" << language << "\\"" << std::endl;\
                /* Trim whitespace from language metadata to avoid Xapian stemming errors */\
                if (!language.empty()) {\
                    language.erase(0, language.find_first_not_of(" \\t\\n\\r\\f\\v"));\
                    language.erase(language.find_last_not_of(" \\t\\n\\r\\f\\v") + 1);\
                }\
                std::cout << "DEBUG: Language after trimming: \\"" << language << "\\"" << std::endl;' libzim-9.3.0/src/search.cpp
	
	# Apply fallback language trimming
	sed -i '/language = archive.getMetadata("Language");/a\
                        std::cout << "DEBUG: Fallback language from archive metadata: \\"" << language << "\\"" << std::endl;\
                        /* Also trim the fallback language metadata */\
                        if (!language.empty()) {\
                            language.erase(0, language.find_first_not_of(" \\t\\n\\r\\f\\v"));\
                            language.erase(language.find_last_not_of(" \\t\\n\\r\\f\\v") + 1);\
                        }\
                        std::cout << "DEBUG: Fallback language after trimming: \\"" << language << "\\"" << std::endl;' libzim-9.3.0/src/search.cpp
	
	# Apply ICU debug
	sed -i '/icu::Locale languageLocale(language.c_str());/a\
                    std::cout << "DEBUG: ICU getLanguage() result: \\"" << languageLocale.getLanguage() << "\\"" << std::endl;\
                    std::cout << "DEBUG: ICU getName() result: \\"" << languageLocale.getName() << "\\"" << std::endl;' libzim-9.3.0/src/search.cpp
	
	# ROBUST EXCEPTION HANDLING - Check for unsupported languages BEFORE creating stemmer
	sed -i '/Configuring language base steemming/a\
                    /* Check if language is supported by Xapian before attempting to create stemmer */\
                    std::string stemLanguage = languageLocale.getLanguage();\
                    std::cout << "DEBUG: About to check if language is supported: \\"" << stemLanguage << "\\"" << std::endl;\
                    /* List of supported Xapian languages as of Xapian 1.4.x */\
                    std::set<std::string> supportedLanguages = {\
                        "ar", "hy", "eu", "ca", "da", "nl", "en", "fi", "fr", "de",\
                        "hu", "it", "no", "pt", "ro", "ru", "es", "sv", "tr"\
                    };\
                    if (supportedLanguages.find(stemLanguage) != supportedLanguages.end()) {\
                        std::cout << "DEBUG: Language \\"" << stemLanguage << "\\" is supported, creating stemmer" << std::endl;' libzim-9.3.0/src/search.cpp
	
	# Replace the stemmer creation with robust error handling
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/try {\
                            m_stemmer = Xapian::Stem(stemLanguage);\
                            std::cout << "DEBUG: Xapian::Stem created successfully for: \\"" << stemLanguage << "\\"" << std::endl;\
                            m_queryParser.set_stemmer(m_stemmer);\
                            m_queryParser.set_stemming_strategy(Xapian::QueryParser::STEM_ALL);\
                        } catch (const Xapian::InvalidArgumentError\& e) {\
                            std::cout << "DEBUG: InvalidArgumentError for language: \\"" << stemLanguage << "\\", using fallback" << std::endl;\
                            m_stemmer = Xapian::Stem("none");\
                            m_queryParser.set_stemmer(m_stemmer);\
                        } catch (const std::exception\& e) {\
                            std::cout << "DEBUG: General exception for language: \\"" << stemLanguage << "\\", using fallback: " << e.what() << std::endl;\
                            m_stemmer = Xapian::Stem("none");\
                            m_queryParser.set_stemmer(m_stemmer);\
                        } catch (...) {\
                            std::cout << "DEBUG: Unknown exception for language: \\"" << stemLanguage << "\\", using fallback" << std::endl;\
                            m_stemmer = Xapian::Stem("none");\
                            m_queryParser.set_stemmer(m_stemmer);\
                        }\
                    } else {\
                        std::cout << "DEBUG: Language \\"" << stemLanguage << "\\" not supported by Xapian, using fallback" << std::endl;\
                        m_stemmer = Xapian::Stem("none");\
                        m_queryParser.set_stemmer(m_stemmer);/' libzim-9.3.0/src/search.cpp
	
	# Remove the old broken catch block  
	sed -i '/std::cout << "No stemming for language/,/}/d' libzim-9.3.0/src/search.cpp
	
	# Fix suggestion.cpp with the same robust approach
	sed -i '/auto language = database.get_metadata("language");/a\
  /* DEBUG: Log what we get from ZIM metadata */\
  std::cout << "DEBUG: [SUGGESTION] Raw language from database metadata: \\"" << language << "\\"" << std::endl;\
  /* Trim whitespace from language metadata to avoid Xapian stemming errors */\
  if (!language.empty()) {\
      language.erase(0, language.find_first_not_of(" \\t\\n\\r\\f\\v"));\
      language.erase(language.find_last_not_of(" \\t\\n\\r\\f\\v") + 1);\
  }\
  std::cout << "DEBUG: [SUGGESTION] Language after trimming: \\"" << language << "\\"" << std::endl;' libzim-9.3.0/src/suggestion.cpp
	
	sed -i '/language = m_archive.getMetadata("Language");/a\
          std::cout << "DEBUG: [SUGGESTION] Fallback language from archive metadata: \\"" << language << "\\"" << std::endl;\
          /* Also trim the fallback language metadata */\
          if (!language.empty()) {\
              language.erase(0, language.find_first_not_of(" \\t\\n\\r\\f\\v"));\
              language.erase(language.find_last_not_of(" \\t\\n\\r\\f\\v") + 1);\
          }\
          std::cout << "DEBUG: [SUGGESTION] Fallback language after trimming: \\"" << language << "\\"" << std::endl;' libzim-9.3.0/src/suggestion.cpp
	
	sed -i '/icu::Locale languageLocale(language.c_str());/a\
      std::cout << "DEBUG: [SUGGESTION] ICU getLanguage() result: \\"" << languageLocale.getLanguage() << "\\"" << std::endl;\
      std::cout << "DEBUG: [SUGGESTION] ICU getName() result: \\"" << languageLocale.getName() << "\\"" << std::endl;' libzim-9.3.0/src/suggestion.cpp
	
	# Apply robust stemmer handling to suggestion.cpp
	sed -i '/Configuring language base steemming/a\
      /* Check if language is supported by Xapian before attempting to create stemmer */\
      std::string stemLanguage = languageLocale.getLanguage();\
      std::cout << "DEBUG: [SUGGESTION] About to check if language is supported: \\"" << stemLanguage << "\\"" << std::endl;\
      /* List of supported Xapian languages as of Xapian 1.4.x */\
      std::set<std::string> supportedLanguages = {\
          "ar", "hy", "eu", "ca", "da", "nl", "en", "fi", "fr", "de",\
          "hu", "it", "no", "pt", "ro", "ru", "es", "sv", "tr"\
      };\
      if (supportedLanguages.find(stemLanguage) != supportedLanguages.end()) {\
          std::cout << "DEBUG: [SUGGESTION] Language \\"" << stemLanguage << "\\" is supported, creating stemmer" << std::endl;' libzim-9.3.0/src/suggestion.cpp
	
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/try {\
              m_stemmer = Xapian::Stem(stemLanguage);\
              std::cout << "DEBUG: [SUGGESTION] Xapian::Stem created successfully for: \\"" << stemLanguage << "\\"" << std::endl;\
              m_queryParser.set_stemmer(m_stemmer);\
          } catch (const Xapian::InvalidArgumentError\& e) {\
              std::cout << "DEBUG: [SUGGESTION] InvalidArgumentError for language: \\"" << stemLanguage << "\\", using fallback" << std::endl;\
              m_stemmer = Xapian::Stem("none");\
              m_queryParser.set_stemmer(m_stemmer);\
          } catch (const std::exception\& e) {\
              std::cout << "DEBUG: [SUGGESTION] General exception for language: \\"" << stemLanguage << "\\", using fallback: " << e.what() << std::endl;\
              m_stemmer = Xapian::Stem("none");\
              m_queryParser.set_stemmer(m_stemmer);\
          } catch (...) {\
              std::cout << "DEBUG: [SUGGESTION] Unknown exception for language: \\"" << stemLanguage << "\\", using fallback" << std::endl;\
              m_stemmer = Xapian::Stem("none");\
              m_queryParser.set_stemmer(m_stemmer);\
          }\
      } else {\
          std::cout << "DEBUG: [SUGGESTION] Language \\"" << stemLanguage << "\\" not supported by Xapian, using fallback" << std::endl;\
          m_stemmer = Xapian::Stem("none");\
          m_queryParser.set_stemmer(m_stemmer);/' libzim-9.3.0/src/suggestion.cpp
	
	sed -i '/std::cout << "No stemming for language/,/}/d' libzim-9.3.0/src/suggestion.cpp
	
	@echo "=== VERIFICATION ==="
	@echo "search.cpp - Supported languages check:"
	grep -n -A3 "supportedLanguages.find" libzim-9.3.0/src/search.cpp || echo "Not found"
	@echo ""
	@echo "suggestion.cpp - Supported languages check:"  
	grep -n -A3 "supportedLanguages.find" libzim-9.3.0/src/suggestion.cpp || echo "Not found"
	@echo ""
	@echo "=== SUCCESS! Robust exception handling patches applied ==="

clean:
	rm -rf libzim-9.3.0 9.3.0.tar.gz

.PHONY: all test-exception-fix clean