# syntax=docker/dockerfile:1

# bump: libgme /LIBGME_COMMIT=([[:xdigit:]]+)/ gitrefs:https://github.com/libgme/game-music-emu.git|re:#^refs/heads/master$#|@commit
# bump: libgme after ./hashupdate Dockerfile LIBGME $LATEST
# bump: libgme link "Source diff $CURRENT..$LATEST" https://github.com/libgme/game-music-emu/compare/$CURRENT..$LATEST
ARG LIBGME_URL="https://github.com/libgme/game-music-emu.git"
ARG LIBGME_COMMIT=265d8b90c9b46bd3b892443dee4da585a0384858

# Must be specified
ARG ALPINE_VERSION

FROM alpine:${ALPINE_VERSION} AS base

FROM base AS download
ARG LIBGME_URL
ARG LIBGME_COMMIT
WORKDIR /tmp
RUN \
  apk add --no-cache --virtual download \
    git && \
  git clone "$LIBGME_URL" libgme && \
  cd libgme && git checkout $LIBGME_COMMIT && \
  apk del download

FROM base AS build
COPY --from=download /tmp/libgme/ /tmp/libgme/
WORKDIR /tmp/libgme/build
RUN \
  apk add --no-cache --virtual build \
    build-base cmake pkgconf && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_UBSAN=OFF \
    .. && \
  make -j$(nproc) install && \
  # Sanity tests
  pkg-config --exists --modversion --path libgme && \
  ar -t /usr/local/lib/libgme.a && \
  readelf -h /usr/local/lib/libgme.a && \
  # Cleanup
  apk del build

FROM scratch
ARG LIBGME_COMMIT
COPY --from=build /usr/local/lib/pkgconfig/libgme.pc /usr/local/lib/pkgconfig/libgme.pc
COPY --from=build /usr/local/lib/libgme.a /usr/local/lib/libgme.a
COPY --from=build /usr/local/include/gme/ /usr/local/include/gme/
