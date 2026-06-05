FROM jenkins/jenkins:lts
USER root

# Install Maven, Ansible, and SSH tools
RUN apt-get update && \
    apt-get install -y maven ansible sshpass openssh-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER jenkins
