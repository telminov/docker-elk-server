# docker build -t telminov/elk-server .

FROM ubuntu:14.04
MAINTAINER telminov@soft-way.biz

# nginx kibana webserver
EXPOSE 80
# logstash beat input
EXPOSE 5044

VOLUME /conf/nginx/     # place for htpasswd.users
VOLUME /data            # elasticsearch data
VOLUME /tls/            # cerstificate paths

RUN apt-get -qqy update && apt-get install -qqy \
                                                unzip \
                                                wget \
                                                curl \
                                                openjdk-7-jdk

RUN wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | apt-key add -
RUN echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
RUN echo "deb http://packages.elastic.co/kibana/4.4/debian stable main" | tee -a /etc/apt/sources.list.d/kibana-4.4.x.list
RUN echo "deb http://packages.elastic.co/logstash/2.2/debian stable main" | tee /etc/apt/sources.list.d/logstash-2.2.x.list

RUN apt-get -qqy update && apt-get install -qqy \
                                                elasticsearch \
                                                kibana \
                                                nginx \
                                                logstash

RUN sed -i 's/.*network\.host.*/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml
RUN sed -i 's/.*path\.data.*/path.data: \/data/' /etc/elasticsearch/elasticsearch.yml
RUN sed -i 's/.*server\.host.*/server.host: localhost/' /opt/kibana/config/kibana.yml

RUN rm /etc/nginx/sites-enabled/default
ADD nginx/kibana /etc/nginx/sites-enabled/kibana

ADD logstash/02-beats-input.conf /etc/logstash/conf.d/02-beats-input.conf
ADD logstash/10-syslog-filter.conf /etc/logstash/conf.d/10-syslog-filter.conf
ADD logstash/30-elasticsearch-output.conf /etc/logstash/conf.d/30-elasticsearch-output.conf

RUN curl -L -O https://download.elastic.co/beats/dashboards/beats-dashboards-1.1.0.zip
RUN unzip beats-dashboards-*.zip
RUN rm beats-dashboards-*.zip
RUN mv beats-dashboards-* beats-dashboards

RUN curl -O https://gist.githubusercontent.com/thisismitch/3429023e8438cc25b86c/raw/d8c479e2a1adcea8b1fe86570e42abab0f10f364/filebeat-index-template.json
RUN curl -O https://raw.githubusercontent.com/elastic/topbeat/master/etc/topbeat.template.json


CMD test "$(ls /conf/nginx/htpasswd.users)" || touch /conf/nginx/htpasswd.users; \
    mkdir /data/elasticsearch; chown elasticsearch:elasticsearch /data/elasticsearch; \
    service elasticsearch start; sleep 2; \
    service kibana start; \
    service nginx start; \
    service logstash start; sleep 2; \
    tail -f /var/log/elasticsearch/elasticsearch.log \
            /var/log/logstash/logstash.log \
            /var/log/kibana/kibana.stdout \
            /var/log/kibana/kibana.stderr
