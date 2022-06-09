# Build Stage
FROM --platform=linux/amd64 ubuntu:20.04 as builder

## Install build dependencies.
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y cmake clang autoconf automake

## Add source code to the build stage.
ADD . /libgphoto2
WORKDIR /libgphoto2
RUN apt -y install autopoint pkg-config libtool
RUN autoreconf -i
RUN CC=clang CXX=clang++ ./configure
RUN make -j3
WORKDIR /libgphoto2/examples
RUN clang -fsanitize=fuzzer -DHAVE_CONFIG_H -I. -I..  -D_GPHOTO2_INTERNAL_CODE -DLOCALEDIR=/usr/local/share/locale -DCAMLIBS=/usr/local/lib/libgphoto2/2.5.29.1 -I.. -I.. -I../libgphoto2_port   -g -O2 -Werror=unknown-warning-option -Wall -Wextra -Wmost -Wno-error=documentation-deprecated-sync -Wno-unused-parameter -c -o sample-libfuzz.o sample-libfuzz.c
RUN clang  -fsanitize=fuzzer -g -O2 -Werror=unknown-warning-option -Wall -Wextra -Wmost -Wno-error=documentation-deprecated-sync -Wno-unused-parameter -o .libs/sample-libfuzz sample-libfuzz.o context.o autodetect.o  ../libgphoto2/.libs/libgphoto2.so ../libgphoto2_port/libgphoto2_port/.libs/libgphoto2_port.so /usr/lib/x86_64-linux-gnu/libltdl.so -lm


# Package Stage
FROM --platform=linux/amd64 ubuntu:20.04

COPY --from=builder /libgphoto2/examples/.libs/sample-libfuzz /sample-libfuzz
COPY --from=builder /libgphoto2/libgphoto2/.libs/libgphoto2.so.6 /lib/x86_64-linux-gnu/libgphoto2.so.6
COPY --from=builder /libgphoto2/libgphoto2_port/libgphoto2_port/.libs/libgphoto2_port.so.12 /lib/x86_64-linux-gnu/libgphoto2_port.so.12
COPY --from=builder /lib/x86_64-linux-gnu/libltdl.so.7 /lib/x86_64-linux-gnu/libltdl.so.7