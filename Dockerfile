# Container image that runs your code
FROM ubuntu:20.04

#Add https transport
RUN apt update && apt install -y apt-transport-https

#Add tzdata
RUN DEBIAN_FRONTEND="noninteractive" apt install -y tzdata

#Add cmake, git, python3, pip, venv, and rsync
RUN apt update && apt install -y cmake git python3 python3-pip python3.8-venv rsync

#Add Github.com known host
RUN ssh-keyscan -H github.com >> /etc/ssh/ssh_known_hosts

#Copy SSH key
#COPY id_rsa /root/.ssh/id_rsa

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
