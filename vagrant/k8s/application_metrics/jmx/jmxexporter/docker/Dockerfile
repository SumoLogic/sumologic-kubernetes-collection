FROM tomcat:jdk8-adoptopenjdk-openj9
RUN apt-get update && apt-get install -y wget
RUN wget https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/0.13.0/jmx_prometheus_javaagent-0.13.0.jar -O /jmx_prometheus_javaagent-0.13.0.jar
ENV CATALINA_OPTS "-javaagent:/jmx_prometheus_javaagent-0.13.0.jar=8888:/config.yaml"
CMD ["catalina.sh", "run"]