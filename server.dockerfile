FROM rust:latest

RUN apt-get -y update && \
    apt-get -y install openssl git

# Add a new user ubuntu, pass: ubuntu
RUN groupadd ubuntu && \
    useradd -rm -d /home/ubuntu -s /bin/bash -g ubuntu -G sudo -u 1000 ubuntu -p "$(openssl passwd -1 ubuntu)"

ENV WORKSPACE=/home/ubuntu/server
RUN mkdir -p $WORKSPACE/bin
RUN cd $WORKSPACE && git clone https://github.com/Abdillah/fuzzable-opc-ua.git && \
    cd fuzzable-opc-ua && \
    cargo build --release && \
    cp ./target/release/opcua-simple-server $WORKSPACE/bin/opc-ua-server && \
    cp ./server.conf $WORKSPACE/bin/server.conf
