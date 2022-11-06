# build off ubuntu later...
FROM python:3.9-alpine

RUN mkdir /app
WORKDIR /app

RUN apk update && \
    apk upgrade && \
	  apk add git && \
	  apk add vim && \
      git clone --depth=1 https://github.com/Dslate88/dotfiles.git
      # TODO: install off compiled hashes? check-in/test this...

# bypass alpine issue with pillow
COPY ./requirements.txt /requirements.txt
RUN apk add --update --no-cache --virtual .tmp gcc libc-dev linux-headers
RUN apk add --no-cache jpeg-dev zlib-dev
RUN pip install -r /requirements.txt
RUN apk del .tmp

COPY . .

# alpine requires #!/bin/sh > #!/bin/bash
CMD ./run.sh

