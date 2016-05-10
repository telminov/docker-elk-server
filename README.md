# docker-elk-server
Container for elasticsearch-logstash-kibana server

## Notes
Generate http-user for base web server authentication like
```
mkdir -p /var/docker/elk_server/conf/nginx/
htpasswd -c /var/docker/elk_server/conf/nginx/htpasswd.users admin
```

Logstash configs
```
mkdir -p /var/docker/elk_server/conf/logstash
```

Generate certificates for filebeat like
```
mkdir -p /var/docker/elk_server/tls/certs
mkdir -p /var/docker/elk_server/tls/private
cd /var/docker/elk_server/tls/
openssl req -config /etc/ssl/openssl.cnf -x509 -days 3650 -batch -nodes -newkey rsa:2048 -keyout private/logstash-forwarder.key -out certs/logstash-forwarder.crt
```

For load beat dashboards:
```
docker exec -ti elk-server bash -c "cd beats-dashboards; ./load.sh"
```

For load filebeat index template to elastic search:
```
docker exec -ti elk-server bash -c "curl -XPUT 'http://localhost:9200/_template/filebeat?pretty' -d@filebeat-index-template.json"
```

For load topbeat index template to elastic search:
```
docker exec -ti elk-server bash -c "curl -XPUT 'http://localhost:9200/_template/topbeat' -d@topbeat.template.json"
```