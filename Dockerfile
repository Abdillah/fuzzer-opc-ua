FROM opc-ua-fuzzer

COPY --from=opc-ua-server /home/ubuntu/server/bin/opc-ua-server $WORKDIR/opc-ua/server
COPY --from=opc-ua-server /home/ubuntu/server/bin/server.conf $WORKDIR/opc-ua/server.conf


# RUN echo "Running ${IT}.${TRY}: ${AFL_BIN} + ${TARGET_BIN}" \
#       echo "Output: ${OUTPUT_FILE}, ${ALF_RESULT_DIR}" \
#       CMD="${AFL_WRAPPER} ${AFL_BIN} -A ./libsbr-afl.so ${AFL_ARGS} -o ./${ALF_RESULT_DIR} ${TARGET_BIN} ${TARGET_CONF} &>./${OUTPUT_FILE}"

USER ubuntu

ENV AFL_ARGS="-t 1000 -m none -i ./in-opcua -P OPC-UA -K -R"
ENV TARGET_BIN=$WORKDIR/opc-ua/server
ENV TARGET_ARGS=
ENV OUTPUT_FILE=$WORKDIR/runlog.txt
ENV AFL_RESULT_DIR=$WORKDIR/results

RUN mkdir -p $AFL_RESULT_DIR

WORKDIR $WORKDIR

USER root
RUN ls $TOOLDIR/
RUN ls $AFLNET/
CMD afl-fuzz -A ./libsnapfuzz.so ${AFL_ARGS} -o ${ALF_RESULT_DIR} ${TARGET_BIN} ${TARGET_ARGS}
