FROM alpine
RUN apk add openjdk17
EXPOSE 80
CMD "JAVA"
