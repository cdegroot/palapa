Credits:

* Basic Dockerfile and scripts: https://github.com/spotify/docker-kafka
* On-the-fly topic creation: https://github.com/wurstmeister/kafka-docker

The topic create script touches the file
`/var/run/topics-created` when everything is done. By mounting this
directory somewhere you can check the container's progress. If the
script errors out, then this file will not be created.

Typical usage:

    docker run -v /tmp/kafkastatus:/var/run -p 9092:9092 cdegroot/kafka
