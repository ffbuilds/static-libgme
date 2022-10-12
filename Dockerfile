
# bump: libgme /LIBGME_COMMIT=([[:xdigit:]]+)/ gitrefs:https://bitbucket.org/mpyne/game-music-emu.git|re:#^refs/heads/master$#|@commit
# bump: libgme after ./hashupdate Dockerfile LIBGME $LATEST
# bump: libgme link "Source diff $CURRENT..$LATEST" https://bitbucket.org/mpyne/game-music-emu/branches/compare/$CURRENT..$LATEST
ARG LIBGME_URL="https://bitbucket.org/mpyne/game-music-emu.git"
ARG LIBGME_COMMIT=6cd4bdb69be304f58c9253fb08b8362f541b3b4b

# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.16.2 AS base

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
    build-base cmake && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_UBSAN=OFF \
    .. && \
  make -j$(nproc) install && \
  apk del build

FROM scratch
ARG LIBGME_COMMIT
COPY --from=build /usr/local/lib/pkgconfig/libgme.pc /usr/local/lib/pkgconfig/libgme.pc
COPY --from=build /usr/local/lib/libgme.a /usr/local/lib/libgme.a
COPY --from=build /usr/local/include/gme/ /usr/local/include/gme/
