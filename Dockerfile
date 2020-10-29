FROM openjdk:11-jdk

# Copy whole app dir since we need gradle to build it
COPY ./application /java-app

WORKDIR /java-app

ENV AWS_DEFAULT_REGION=us-east-1

USER root
RUN ./gradlew build -x test

VOLUME /tmp

CMD java -Dserver.port=80 -jar ./build/libs/helloworld-1.0.0.jar