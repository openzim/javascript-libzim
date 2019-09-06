FROM trzeci/emscripten:sdk-tag-1.38.35-64bit

# Install build tools
RUN apt update && apt install -y wget ninja-build meson pkg-config python3 autopoint libtool autoconf patch g++ locales curl git
# The following packages are needed for meson build, even if they are unused for compilation
RUN apt install -y zlib1g-dev libicu-dev libxapian-dev liblzma-dev libcurl4-openssl-dev

# Set the locale to UTF-8, to avoid some compilation warnings
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8 
