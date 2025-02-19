# Docker image suitable to build libzim & kiwixlib with emscripten
ARG VERSION
FROM emscripten/emsdk:${VERSION}

# Install build tools
RUN apt-get update && apt-get install -y --no-install-recommends wget ninja-build pkg-config python3 autopoint libtool autoconf patch g++ locales curl git \
# The following packages are needed for meson build, even if they are unused for compilation
	zlib1g-dev libicu-dev libxapian-dev liblzma-dev libcurl4-openssl-dev \
# To avoid the error 'aclocal not found', we have to install automake
    automake \
  # Clean the apt-get list to keep the image size low 	
	&& apt-get clean \
 	&& rm -rf /var/lib/apt/lists/*

# We need a more recent version of meson to workaround https://github.com/mesonbuild/meson/issues/6684
RUN pip install --no-cache-dir meson

# Set the locale to UTF-8, to avoid some compilation warnings
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && locale-gen
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create the cache directory with the good rights
RUN mkdir /home/emscripten/.emscripten_cache && chown emscripten:emscripten /home/emscripten/.emscripten_cache

# Indicates that the sources to compile should be mounted in /src when running the container
VOLUME /src
# It's better to keep the emscripten cache between builds to improve performance
VOLUME /home/emscripten/.emscripten_cache
