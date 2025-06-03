#!/usr/bin/make -f

# More robust exception handling approach
# Run with: make -f test-robust-fix.mk

all: test-robust-fix

test-robust-fix:
	@echo "=== Downloading fresh libzim 9.3.0 ==="
	rm -rf libzim-9.3.0 9.3.0.tar.gz
	wget -q https://github.com/openzim/libzim/archive/9.3.0.tar.gz
	tar -xzf 9.3.0.tar.gz
	
	@echo "=== APPLYING ROBUST EXCEPTION PATCHES ==="
	
	# SEARCH.CPP - More explicit exception handling
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/try { m_stemmer = Xapian::Stem(languageLocale.getLanguage()); } catch (const Xapian::InvalidArgumentError\& e) { m_stemmer = Xapian::Stem("none"); } catch (const std::exception\& e) { m_stemmer = Xapian::Stem("none"); } catch (...) { m_stemmer = Xapian::Stem("none"); }/' libzim-9.3.0/src/search.cpp
	
	# SUGGESTION.CPP - More explicit exception handling  
	sed -i 's/m_stemmer = Xapian::Stem(languageLocale.getLanguage());/try { m_stemmer = Xapian::Stem(languageLocale.getLanguage()); } catch (const Xapian::InvalidArgumentError\& e) { m_stemmer = Xapian::Stem("none"); } catch (const std::exception\& e) { m_stemmer = Xapian::Stem("none"); } catch (...) { m_stemmer = Xapian::Stem("none"); }/' libzim-9.3.0/src/suggestion.cpp
	
	@echo "=== VERIFICATION ==="
	@echo "search.cpp - Robust exception handling: $$(grep -c 'InvalidArgumentError' libzim-9.3.0/src/search.cpp || echo '0')"
	@echo "suggestion.cpp - Robust exception handling: $$(grep -c 'InvalidArgumentError' libzim-9.3.0/src/suggestion.cpp || echo '0')"
	@echo ""
	@echo "=== SUCCESS! Robust exception patches applied ==="

clean:
	rm -rf libzim-9.3.0 9.3.0.tar.gz

.PHONY: all test-robust-fix clean