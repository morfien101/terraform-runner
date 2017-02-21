FROM centos:7
MAINTAINER Randy Coburn - morfien101 (at) gmail (dot) com

ENV TERRAFORM_VERSION=0.8.4
ENV TERRAFORM_RUNNER_VERSION=0.1.5

RUN yum makecache \
    && yum install -y ruby git curl unzip which \
    && curl -L https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip > /tmp/terraform.zip \
    && yum clean all \
    && unzip /tmp/terraform.zip \
    && rm -f /tmp/terraform.zip \
    && mv terraform* /usr/local/bin/ \
    && chmod 770 /usr/local/bin/terraform \
    && git clone https://github.com/morfien101/terraform-runner.git \
    && curl https://raw.githubusercontent.com/morfien101/terraform-runner-gem/master/terraform_runner-${TERRAFORM_RUNNER_VERSION}.gem --create-dirs -o /terraform-runner/terraform_runner-${TERRAFORM_RUNNER_VERSION}.gem \
    && cd /terraform-runner \
    && gem install /terraform-runner/terraform_runner-${TERRAFORM_RUNNER_VERSION}.gem \
    && for i in $(ls -p | grep -v / | grep -v terraform-runner); do rm -f $i; done \
    && for i in $(ls | grep .rb); do chmod 770 $i; done \
    && cd .. \
    && echo "cd /terraform-runner" >> /root/.bashrc

CMD ["/bin/bash"]
