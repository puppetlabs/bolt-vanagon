FROM ubuntu:16.04

ARG version="1.24.0"
ARG vcs_ref
ARG build_date

ENV BOLT_VERSION="$version"
ENV UBUNTU_CODENAME="xenial"
ENV BOLT_DISABLE_ANALYTICS="true"

LABEL org.label-schema.maintainer="Puppet Release Team <release@puppet.com>" \
      org.label-schema.vendor="Puppet" \
      org.label-schema.url="https://github.com/puppetlabs/bolt-vanagon" \
      org.label-schema.name="Puppet Bolt" \
      org.label-schema.license="Apache-2.0" \
      org.label-schema.version=$BOLT_VERSION \
      org.label-schema.vcs-url="https://github.com/puppetlabs/bolt-vanagon" \
      org.label-schema.vcs-ref="vcs_ref" \
      org.label-schema.build-date="build_date" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.dockerfile="/Dockerfile"

RUN apt-get update && \
    apt-get install --no-install-recommends -y wget ca-certificates lsb-release && \
    wget http://apt.puppetlabs.com/puppet-enterprise-tools-release-"$UBUNTU_CODENAME".deb && \
    dpkg -i puppet-enterprise-tools-release-"$UBUNTU_CODENAME".deb && \
    rm puppet-enterprise-tools-release-"$UBUNTU_CODENAME".deb && \
    apt-get update && \
    apt-get install --no-install-recommends -y puppet-bolt="$BOLT_VERSION"-1"$UBUNTU_CODENAME" && \
    apt-get remove --purge -y wget && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH=/opt/puppetlabs/bin:$PATH

ENTRYPOINT ["/opt/puppetlabs/bin/bolt"]
CMD ["help"]

COPY Dockerfile /