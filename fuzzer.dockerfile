FROM ubuntu:20.04

# Install common dependencies
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update && \
    apt-get -y install sudo \
    apt-utils \
    build-essential \
    openssl \
    clang \
    graphviz-dev \
    git \
    autoconf \
    libgnutls28-dev \
    libssl-dev \
    llvm \
    python3-pip \
    nano \
    net-tools \
    vim \
    gdb \
    netcat \
    strace \
    wget \
    libtool \
    cmake \
    cmake-curses-gui \
    libsqlite3-dev \
    gettext-base \
    libelf-dev \
    libc6-dbg

# Add a new user ubuntu, pass: ubuntu
RUN groupadd ubuntu && \
    useradd -rm -d /home/ubuntu -s /bin/bash -g ubuntu -G sudo -u 1000 ubuntu -p "$(openssl passwd -1 ubuntu)"

RUN chmod 777 /tmp

RUN pip3 install gcovr==4.2

# Use ubuntu as default username
USER ubuntu
WORKDIR /home/ubuntu

# Import environment variable to pass as parameter to make (e.g., to make parallel builds with -j)
ARG MAKE_OPT

# Set up fuzzers
ENV TOOLDIR="/home/ubuntu/tools"
RUN mkdir $TOOLDIR && cd $TOOLDIR

RUN git clone https://github.com/andronat/aflnet.git --branch mymaster --single-branch aflnet && \
    cd aflnet && \
    make clean all $MAKE_OPT && \
    cd llvm_mode && make $MAKE_OPT

RUN git clone https://github.com/profuzzbench/aflnwe.git && \
    cd aflnwe && \
    make clean all $MAKE_OPT && \
    cd llvm_mode && make $MAKE_OPT

RUN git clone --recurse-submodules https://github.com/srg-imperial/SnapFuzz.git && \
    cd SnapFuzz/ && \
    ln -s $(realpath snapfuzz) SaBRe/plugins/snapfuzz && \
    cd SaBRe/ && \
    mkdir build && \
    cd build/ && cmake .. && \
    make -j && ls plugins && \
    cp sabre $TOOLDIR/ && \
    cp plugins/snapfuzz/libsnapfuzz.so $TOOLDIR/

# TODO: SnapFuzz original script hint at several plugin compilation modes
#       that may produce multiple kind of the library.

# Set up environment variables for AFLNet
ENV WORKDIR="/home/ubuntu/experiments"
ENV AFLNET="/home/ubuntu/aflnet"
ENV PATH="${PATH}:${AFLNET}:/home/ubuntu/.local/bin:${TOOLDIR}"
ENV AFL_PATH="${AFLNET}"
ENV AFL_I_DONT_CARE_ABOUT_MISSING_CRASHES=1 \
    AFL_SKIP_CPUFREQ=1 \
    AFL_NO_AFFINITY=1

RUN mkdir $WORKDIR

# COPY --chown=ubuntu:ubuntu fuzzing.patch ${WORKDIR}/fuzzing.patch
# COPY --chown=ubuntu:ubuntu gcov.patch ${WORKDIR}/gcov.patch

# # Setup Open62541 OPC-UA library
# RUN cd ${WORKDIR} && git clone https://github.com/open62541/open62541.git && \
#     cd open62541 && \
#     mkdir build && cd build && \
#     cmake -DCMAKE_BUILD_TYPE=Release \
#     	  -DUA_ENABLE_AMALGAMATION=ON \
#     	  -DUA_BUILD_EXAMPLES=OFF && \
#     make -j && make install

# RUN cd ${WORKDIR} && git clone git@github.com:alongL/opcuaServer.git && \
#     cd opcuaServer && \
#     make -j

# # Set up environment variables for ASAN
# env ASAN_OPTIONS='abort_on_error=1:symbolize=0:detect_leaks=0:detect_stack_use_after_return=1:detect_container_overflow=0:poison_array_cookie=0:malloc_fill_byte=0:max_malloc_fill_size=16777216'

# # Set up LightFTP for fuzzing
# RUN cd ${WORKDIR}/LightFTP/Source/Release && \
#     cp ${AFLNET}/tutorials/lightftp/fftp.conf ./ && \
#     cp ${AFLNET}/tutorials/lightftp/ftpclean.sh ./ && \
#     cp -r ${AFLNET}/tutorials/lightftp/certificate /home/ubuntu && \
#     mkdir /home/ubuntu/ftpshare

# # Download and compile LightFTP for coverage analysis
# RUN cd $WORKDIR && \
#     git clone https://github.com/hfiref0x/LightFTP.git LightFTP-gcov && \
#     cd LightFTP-gcov && \
#     git checkout 5980ea1 && \
#     patch -p1 < ${WORKDIR}/gcov.patch && \
#     cd Source/Release && \
#     make CFLAGS="-fprofile-arcs -ftest-coverage" CPPFLAGS="-fprofile-arcs -ftest-coverage" CXXFLAGS="-fprofile-arcs -ftest-coverage" LDFLAGS="-fprofile-arcs -ftest-coverage" clean all $MAKE_OPT

# # Set up LightFTP for fuzzing
# RUN cd ${WORKDIR}/LightFTP-gcov/Source/Release && \
#     cp ${AFLNET}/tutorials/lightftp/fftp.conf ./ && \
#     cp ${AFLNET}/tutorials/lightftp/ftpclean.sh ./

COPY --chown=ubuntu:ubuntu in-opcua ${WORKDIR}/in-opcua
COPY --chown=ubuntu:ubuntu cov_script.sh ${WORKDIR}/cov_script
COPY --chown=ubuntu:ubuntu run.sh ${WORKDIR}/run
COPY --chown=ubuntu:ubuntu clean.sh ${WORKDIR}/ftpclean
