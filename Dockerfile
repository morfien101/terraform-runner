FROM ubuntu
MAINTAINER Randy Coburn - morfien101 (at) gmail (dot) com

ENV TERRAFORM_VERSION=0.7.13

RUN apt-get update \
    && apt-get install -y -q ruby2.3 git curl \
    && curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > /tmp/terraform.zip \
    && unzip /tmp/terraform.zip \
    && mv terraform* /usr/local/bin/ \
    && chmod 770 /usr/local/bin/terraform \
    && git clone https://github.com/morfien101/terraform-runner.git \
    && chmod 770 /terraform-runner/terraform-runner.rb \
    && echo "cd /terraform-runner" >> /etc/bash.bashrc

CMD ["/bin/bash"]
