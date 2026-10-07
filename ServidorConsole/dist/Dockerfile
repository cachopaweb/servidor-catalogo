FROM jacobalberty/firebird

RUN apt-get update -y && apt upgrade -y && apt-get dist-upgrade -y
# RUN apt-get install -y zlib1g-dev
RUN apt-get install -y libcurl4-gnutls-dev

COPY ./ServidorApp ./app/ServidorApp

EXPOSE 8080

ENTRYPOINT ./app/ServidorApp