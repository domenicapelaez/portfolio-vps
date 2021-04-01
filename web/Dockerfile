FROM apachephp
RUN apt update && apt install -yq --no-install-recommends \
    openssh-server \
    openssh-client \
    sudo \
    apache2 \
    git

EXPOSE 80

COPY ./addhosts /root
COPY ./id_rsa.pub /root
COPY ./start.sh /root

RUN dos2unix /root/start.sh
RUN chmod +x /root/start.sh

ENTRYPOINT [ "/root/start.sh" ]
