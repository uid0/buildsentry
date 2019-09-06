FROM alpine:3.10

ENV TERRAFORM_VERSION=0.12.7
ENV PACKER_VERISON=1.4.3

VOLUME ["/data"]

WORKDIR /data

ENTRYPOINT ["/bin/bash"]

RUN apk update && \
  apk add --no-cache curl jq python bash ca-certificates git openssl unzip wget python py-pip openssh-client && \
  apk --update add --virtual build-dependencies python-dev libffi-dev openssl-dev build-base && \
  pip install --upgrade pip cffi && \
  pip install ansible awscli && \
  cd /tmp && \
  wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip && \
  wget https://releases.hashicorp.com/packer/${PACKER_VERISON}/packer_${PACKER_VERISON}_linux_amd64.zip && \
  unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip -d /usr/bin && \
  unzip packer_${PACKER_VERISON}_linux_amd64.zip -d /usr/bin && \
  chmod a+x /usr/bin/terraform /usr/bin/packer && \
  rm -rf /tmp/* && \
  rm -rf /var/cache/apk/*