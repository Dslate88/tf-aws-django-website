FROM nginx

COPY nginx.conf /etc/nginx/nginx.conf

ENV HOME=/home/app
RUN mkdir $HOME
RUN mkdir $HOME/static
RUN mkdir $HOME/media

COPY nginx.conf /etc/nginx/nginx.conf
COPY media/ /home/app/media/
COPY static/ /home/app/static/
