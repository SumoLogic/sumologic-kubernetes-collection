FROM tomcat:jdk8-adoptopenjdk-openj9
RUN apt-get update && apt-get install -y wget
RUN wget https://search.maven.org/remotecontent?filepath=org/jolokia/jolokia-jvm/1.6.2/jolokia-jvm-1.6.2-agent.jar -O /jolokia-jvm-1.6.2-agent.jar
ENV CATALINA_OPTS "-javaagent:/jolokia-jvm-1.6.2-agent.jar"
CMD ["catalina.sh", "run"]