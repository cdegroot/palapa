# Kafka and Zookeeper

FROM java:openjdk-8-jre

ENV DEBIAN_FRONTEND noninteractive
ENV SCALA_VERSION 2.12
ENV KAFKA_VERSION 0.11.0.2
ENV KAFKA_HOME /opt/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION"

# My defaults
ENV ADVERTISED_HOST 127.0.0.1

# Install Kafka, Zookeeper and other needed things
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y zookeeper wget supervisor dnsutils net-tools
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get clean && \
    wget -q http://apache.mirrors.spacedump.net/kafka/"$KAFKA_VERSION"/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -O /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz && \
    tar xfz /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz -C /opt && \
    rm /tmp/kafka_"$SCALA_VERSION"-"$KAFKA_VERSION".tgz

ADD scripts/start-kafka.sh /usr/bin/start-kafka.sh
ADD scripts/create-topics.sh /usr/bin/create-topics.sh

# Supervisor config
ADD supervisor/kafka.conf supervisor/zookeeper.conf supervisor/create-topics.conf \
    /etc/supervisor/conf.d/

# Tweak kafka config. It's generally useful for test environments to have auto create
# topics on; also, two partitions will exercise for the in-production-many-partitions case
# better
# Note: the extra echo ensures the original config file has an ending newline. This is
# more portable than stuff like "echo -e '\n....'"
RUN sed -i.bak 's/num.partitions=1/num.partitions=2/' $KAFKA_HOME/config/server.properties && \
    echo >>$KAFKA_HOME/config/server.properties && \
    echo 'auto.create.topics.enable=true' >>$KAFKA_HOME/config/server.properties

# 2181 is zookeeper, 9092 is kafka
EXPOSE 2181 9092

CMD ["supervisord", "-n"]
