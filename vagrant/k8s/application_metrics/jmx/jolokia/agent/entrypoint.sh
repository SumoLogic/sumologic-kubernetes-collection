#!/bin/bash
bash catalina.sh run 2>&1 | tee -a /tmp/stdout.log &
sleep 5
java -jar /jolokia-jvm-1.6.2-agent.jar start org.apache.catalina.startup.Bootstrap 2>&1 | tee -a /tmp/stdout.log &
tail -f /tmp/stdout.log
