FROM tomcat:jdk8-adoptopenjdk-openj9
RUN apt-get update && apt-get install -y curl
RUN curl -L https://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/1.6.2/jolokia-jvm-1.6.2-agent.jar -o /jolokia-jvm-1.6.2-agent.jar
COPY entrypoint.sh /entrypoint.sh
CMD ["/entrypoint.sh"]
