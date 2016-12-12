FROM centos:7
MAINTAINER Randy Coburn - morfien101 (at) gmail (dot) com

ENV TERRAFORM_VERSION=0.7.13

RUN yum makecache \
    && yum install -y ruby git curl unzip which\
    && curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > /tmp/terraform.zip \
    && yum clean all \
    && unzip /tmp/terraform.zip \
    && mv terraform* /usr/local/bin/ \
    && chmod 770 /usr/local/bin/terraform \
    && git clone https://github.com/morfien101/terraform-runner.git \
    && chmod 770 /terraform-runner/terraform-runner.rb \
    && echo "cd /terraform-runner" >> /root/.bashrc

CMD ["/bin/bash"]
