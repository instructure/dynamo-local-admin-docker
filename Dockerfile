# I'd like to use alpine, but for some reason, DynamoDB Local seems to hang
# in all the alpine java images.
FROM openjdk:8-jre

MAINTAINER Zach Wily <zach@instructure.com>

# We need java and node in this image, so we'll start with java (cause it's
# more hairy), and then dump in the node Dockerfile below. It'd be nice if there
# was a more elegant way to compose at the image level, but I suspect the
# response here would be "use two containers".

################################################################################
## START COPY FROM https://github.com/nodejs/docker-node
################################################################################
##
## Released under MIT License
## Copyright (c) 2015 Joyent, Inc.
## Copyright (c) 2015 Node.js contributors
##

# gpg keys listed at https://github.com/nodejs/node
RUN set -ex \
  && for key in \
    4ED778F539E3634C779C87C6D7062848A1AB005C \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    74F12602B6F1C4E913FAA37AD3A89613643B6201 \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    8FCCA13FEF1D0C2E91008E09770F7A9A5AE15600 \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    A48C2BEE680E841632CD4E44F07496B3EB3C1762 \
    108F52B48DB57BB0CC439B2997B01419BD92F80A \
    B9E2F5981AA6E0CD28160D9FF13993A75599653C \
  ; do \
    gpg --keyserver keys.openpgp.org --recv-keys "$key"; \
  done


ENV NPM_CONFIG_LOGLEVEL info
ENV NODE_VERSION 16.13.2

RUN curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-x64.tar.xz" \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-x64.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-x64.tar.xz" -C /usr/local --strip-components=1 \
  && rm "node-v$NODE_VERSION-linux-x64.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt

################################################################################
## END COPY
################################################################################

RUN npm install -g dynamodb-admin

RUN cd /usr/lib && \
    curl -L https://s3-us-west-2.amazonaws.com/dynamodb-local/dynamodb_local_latest.tar.gz | tar xz
RUN mkdir -p /var/lib/dynamodb
VOLUME /var/lib/dynamodb

RUN apt-get update && \
    apt-get install -y supervisor nginx && \
    apt-get clean && \
    rm -fr /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY nginx-proxy.conf /etc/nginx-proxy.conf
COPY supervisord.conf /etc/supervisord.conf
RUN mkdir -p /var/log/supervisord

# Configuration for dynamo-admin to know where to hit dynamo.
ENV DYNAMO_ENDPOINT http://localhost:8002/

# For dinghy users.
ENV VIRTUAL_HOST dynamo.docker
ENV VIRTUAL_PORT 8000

# Main proxy on 8000, dynamo-admin on 8001, dynamodb on 8002
EXPOSE 8000 8001 8002

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
