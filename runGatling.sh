#!/bin/bash
set -x

>test-result.md

JAVA_VERSION=$(java -version 2>&1 |grep version)
DATE=$(date +"%Y-%m-%d %T")
SB=$(grep spring-boot-starter-parent spring-boot/pom.xml -A1|grep -oPm1 "(?<=<version>)[^<]+")
HEL=$(grep helidon-se helidon-se-netty/pom.xml -A1|grep ver|grep -oPm1 "(?<=<version>)[^<]+")
QU=$(grep quarkus.platform.version quarkus/pom.xml |grep -v "\\$"|grep -oPm1 "(?<=<quarkus.platform.version>)[^<]+")
MICRO=$(grep parent micronaut/pom.xml -A1|grep -oPm1 "(?<=<version>)[^<]+")
VERTX=$(grep vertx vertx/pom.xml|grep -oPm1 "(?<=<vertx.version>)[^<]+")

sed -i "s/Spring boot:.*/Spring boot:$SB/g" README.md
sed -i "s/Helidon:.*/Helidon:$HEL/g" README.md
sed -i "s/Quarkus:.*/Quarkus:$QU/g" README.md
sed -i "s/Micronaut:.*/Micronaut:$MICRO/g" README.md
sed -i "s/Vertx:.*/Vertx:$VERTX/g" README.md

echo "---
layout: post
title:  'Java microservice framework tests in SB:$SB Q:$QU M:$MICRO V:$VERTX H:$HEL $JAVA_VERSION'
date:   $DATE
categories: java,fasterxml,json
--- 
Here is total package generation times for separate modules,
{% highlight bash %}
" >> test-result.md
mvn -T 1C test package|grep SUCCESS|grep -Ev "(framework|gatling|BUILD)" >>test-result.md
echo '{% endhighlight %}' >> test-result.md
echo 'Size of created packages:

| Size in MB |  Name |
|------------|-------|' >> test-result.md
ls -lh */target/*.jar|grep M|grep -v shaded|awk '{print "|",$5,"|",$9,"|"}' >>test-result.md
printf '\n\n' >> test-result.md
echo 'Running jars and collecting test results...'

test (){
    >log.log
    jarPath=$1
    verInfo=$2
    startTime=$3
    java -jar $jarPath > log.log & 
    
    JPID=$!

    until curl -sf http://localhost:8080/hello; do
        printf '.'
        sleep 0.4
    done

    frameworkVersion=`grep -m1 -o "$verInfo.*" log.log`
    startTime=`grep -m1 -o "$startTime.*" log.log`

    echo $frameworkVersion $startTime >> test-result.md
    printf "\nGatling test starting... for $jarPath"
    echo '
    {% highlight bash %}' >> test-result.md
    mvn -f gatling/pom.xml gatling:test|grep -A10 "Global Information" >> test-result.md
    echo '{% endhighlight %}' >> test-result.md
    kill -9 $JPID
    printf '\n' >> test-result.md
    sleep 2
}

test "spring-boot/target/springboot-demo-0.0.1-SNAPSHOT.jar" ":: Spring Boot ::" "Started DemoApplication"
test "quarkus/target/quarkus-demo-1.0.0-SNAPSHOT-runner.jar" "powered by Quarkus" "WWWWW"
test "micronaut/target/micronaut-demo-0.1.jar" "micronaut version" "Startup completed in"
test "vertx/target/vertx-demo-1.0.0-SNAPSHOT-fat.jar" "vertx version" "XXXXX"
test "eclipse-microprofile-kumuluz-test/target/eclipse-microprofile-kumuluz-test.jar" "kumuluz version:" "Server -- Started"
test "helidon-se-netty/target/helidon-quickstart-se.jar" "Helidon SE" "XXXXX"



