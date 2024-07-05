FROM ubuntu:lts

RUN apt-get update \
  && apt install -y python3-pip python3-venv

RUN python3 -m venv env \
  && source env/bin/activate \
  && pip3 install ansible pywinrm[credssp]

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
