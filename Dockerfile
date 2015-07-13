FROM heroku/cedar:14

RUN useradd -d /app -m app
USER app
RUN mkdir -p /app/src
WORKDIR /app/src


## Install Haproxy

RUN mkdir -p /app/custom/haproxy 

ENV HAPROXY_MAJOR 1.5
ENV HAPROXY_VERSION 1.5.14
ENV HAPROXY_MD5 ad9d7262b96ba85a0f8c6acc6cb9edde

RUN set -x \
  && curl -SL "http://www.haproxy.org/download/${HAPROXY_MAJOR}/src/haproxy-${HAPROXY_VERSION}.tar.gz" -o /tmp/haproxy.tar.gz \
  && echo "${HAPROXY_MD5}  /tmp/haproxy.tar.gz" | md5sum -c \
  && mkdir -p /tmp/src/haproxy \
  && tar -xzf /tmp/haproxy.tar.gz -C /tmp/src/haproxy --strip-components=1 \
  && rm /tmp/haproxy.tar.gz \
  && make -C /tmp/src/haproxy \
    SBINDIR=/app/custom/haproxy/bin \
    TARGET=linux2628 \
    USE_PCRE=1 PCREDIR= \
    USE_OPENSSL=1 \
    USE_ZLIB=1 \
    all \
    install-bin \
  && rm -rf /tmp/src/haproxy 

ENV PATH /app/custom/haproxy/bin:$PATH

# END haproxy install

ENV HOME /app
ENV RUBY_ENGINE 2.2.1
ENV BUNDLER_VERSION 1.7.12
ENV NODE_ENGINE 0.10.38
ENV PORT 3000

RUN mkdir -p /app/heroku/ruby
RUN curl -s https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/cedar-14/ruby-$RUBY_ENGINE.tgz | tar xz -C /app/heroku/ruby
ENV PATH /app/heroku/ruby/bin:$PATH

RUN mkdir -p /app/heroku/bundler
RUN mkdir -p /app/src/vendor/bundle
RUN curl -s https://s3-external-1.amazonaws.com/heroku-buildpack-ruby/bundler-$BUNDLER_VERSION.tgz | tar xz -C /app/heroku/bundler
ENV PATH /app/heroku/bundler/bin:$PATH
ENV GEM_PATH=/app/heroku/bundler:$GEM_PATH
ENV GEM_HOME=/app/src/vendor/bundle

RUN mkdir -p /app/heroku/node
RUN curl -s https://s3pository.heroku.com/node/v$NODE_ENGINE/node-v$NODE_ENGINE-linux-x64.tar.gz | tar --strip-components=1 -xz -C /app/heroku/node
ENV PATH /app/heroku/node/bin:$PATH
WORKDIR /app/src


# creat start script that reassigns stdout to allow us to bypass upstart
RUN echo "#!/bin/bash" > /app/custom/start
RUN echo "exec 5>&1" >> /app/custom/start
RUN echo "/sbin/init --user --no-sessions --session --confdir=/app/custom/upstart  --logdir=/app/src/logs/" >> /app/custom/start
RUN echo "exec 1>&5 5>&-" >> /app/custom/start
RUN chmod +x /app/custom/start



## BUILD

ONBUILD COPY Gemfile /app/src/
ONBUILD COPY Gemfile.lock /app/src/

ONBUILD USER root
ONBUILD RUN chown app /app/src/Gemfile* # ensure user can modify the Gemfile.lock
ONBUILD USER app

ONBUILD RUN bundle install # TODO: desirable if --path parameter were passed

ONBUILD COPY . /app/src

ONBUILD USER root
ONBUILD RUN chown -R app /app
ONBUILD USER app

ONBUILD RUN mkdir -p /app/.profile.d
ONBUILD RUN echo "export PATH=\"/app/custom/haproxy/bin:/app/heroku/ruby/bin:/app/heroku/bundler/bin:/app/heroku/node/bin:\$PATH\"" > /app/.profile.d/ruby.sh
ONBUILD RUN echo "export GEM_PATH=\"/app/heroku/bundler:/app/heroku/src/vendor/bundle:\$GEM_PATH\"" >> /app/.profile.d/ruby.sh
ONBUILD RUN echo "export GEM_HOME=\"/app/src/vendor/bundle\"" >> /app/.profile.d/ruby.sh

ONBUILD RUN echo "cd /app/src" >> /app/.profile.d/ruby.sh



## register upstart scripts & logs
ONBUILD RUN mkdir -p /app/custom/upstart
ONBUILD RUN cp /app/src/init/*.conf /app/custom/upstart/ 

ONBUILD RUN mkdir -p /app/src/logs


ONBUILD EXPOSE 3000
