FROM alpine:latest
# MAINTAINER Matt Bentley <mbentley@mbentley.net>
LABEL Maintainer_Name="Tom Wizda"
LABEL Maintainer_Email="twizda@mirantis.com"
LABEL BuildDate="20241119"

RUN apk add --no-cache bash curl jq

COPY swarm_core_audit.sh /swarm_core_audit.sh

CMD ["/swarm_core_count.sh"]
