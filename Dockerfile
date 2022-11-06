FROM python:3.9-buster
RUN mkdir /app
WORKDIR /app

RUN apt-get update && apt-get install nginx vim -y --no-install-recommends
COPY ./requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

COPY . .

CMD ./run.sh
