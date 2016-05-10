# docker build -t telminov/elk-server .

FROM ubuntu:14.04
MAINTAINER telminov@soft-way.biz

# nginx kibana webserver
EXPOSE 80
# logstash beat input
EXPOSE 5044

VOLUME /conf/nginx/     # place for htpasswd.users
VOLUME /conf/logstash/  # place for logstash configs
VOLUME /data            # elasticsearch data
VOLUME /tls/            # cerstificate paths

RUN apt-get -qqy update && apt-get install -qqy \
                                                vim \
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

ADD  logstash /etc/logstash/conf-sample

RUN curl -L -O https://download.elastic.co/beats/dashboards/beats-dashboards-1.1.0.zip
RUN unzip beats-dashboards-*.zip
RUN rm beats-dashboards-*.zip
RUN mv beats-dashboards-* beats-dashboards

ADD elasticsearch/filebeat-index-template.json filebeat-index-template.json
ADD elasticsearch/topbeat.template.json topbeat.template.json


CMD test "$(ls /conf/nginx/htpasswd.users)" || touch /conf/nginx/htpasswd.users; \
    test "$(ls /conf/logstash/*)" || cp /etc/logstash/conf-sample/* /conf/logstash/; \
    rm -rf /etc/logstash/conf.d/*; cp /conf/logstash/* /etc/logstash/conf.d/; \
    mkdir /data/elasticsearch; chown -R elasticsearch:elasticsearch /data; \
    chown -R www-data:www-data  /conf/nginx/; \
    service elasticsearch start; sleep 2; \
    service kibana start; \
    service nginx start; \
    service logstash start; sleep 2; \
    tail -f /var/log/elasticsearch/elasticsearch.log \
            /var/log/logstash/logstash.log \
            /var/log/kibana/kibana.stdout \
            /var/log/kibana/kibana.stderr
