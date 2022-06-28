#Dockerfile to webchain-pool
#made by Skiff (skiffax)
#version: 33
#
#run container with next instructions:
#sudo docker run -p 80:80 -p 8080:8080 -p 39573:39573 -p 68:68 -p 31140:31140 -d --name skiffcontainer1.33.3 --privileged=true -v /sys/fs/cgroup:/sys/fs/cgroup:ro skiffdocker:1.33 /sbin/init && /home/webchain/geth --mintme

FROM jrei/systemd-debian:latest

ENV HOME="/home/webchain"
ENV IP_SERVER="192.168.1.212"

RUN apt-get -y update && apt-get install -y redis-server \
    golang-go \
    bash \
    nodejs
RUN DEBIAN_FRONTEND=noninteractive TZ=Europe/Kiev apt-get install -y sudo wget openssh-server software-properties-common build-essential tcl git unzip curl python net-tools nginx

#configuring redis /etc/redis/redis.conf “supervised no” -> change it to “supervised systemd”
RUN sed -i 's/supervised no/supervised systemd/' /etc/redis/redis.conf
RUN rm /bin/sh && ln -s /bin/bash /bin/sh
RUN chsh -s /bin/bash
WORKDIR $HOME

RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

#copy webchain's services
COPY ./services-systemd/webchain* /etc/systemd/system/
#RUN ls -la /etc/systemd/system/

#configuring nginx
COPY ./config-nginx/default /etc/nginx/sites-available/default
RUN sed -i 's/root \/var\/www\/html;/root $HOME\/webchain-pool\/www\/dist;/' /etc/nginx/sites-available/default
RUN sed -i 's/\/home\/webchain\/$HOME\webchain-pool\/www\/dist;/$HOME\/webchain-pool\/www\/dist;/' /etc/nginx/sites-available/default

#creation user "webchain"
RUN useradd -ms /bin/bash webchain
#RUN mkdir /home/webchain
RUN chown -R webchain:webchain /home/webchain
#RUN echo $USER

#Installation of nodejs and npm
#следующая - попытка установить ноду
#RUN apt-get install -y nodejs
#возможное решения: одно из двух
#RUN apt-get install nodejs-legacy
#RUN ln -s /usr/bin/nodejs /usr/bin/node

#Installation of GO
RUN curl -O https://dl.google.com/go/go1.13.3.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.13.3.linux-amd64.tar.gz
#switch user
USER webchain
RUN touch ~/.bashrc
RUN echo "export PATH=$PATH:$HOME/go/bin:/usr/local/go/bin" >> $HOME/.bashrc
RUN chmod 777 ~/.bashrc
#RUN chmod 777 ./bashrc
RUN \. ~/.bashrc

#geth
RUN wget https://github.com/etclabscore/core-geth/releases/download/v1.12.7/core-geth-linux-v1.12.7.zip && unzip core-geth-linux-v1.12.7.zip
RUN chown -R webchain:webchain $HOME/geth

#USER webchain
#RUN export HOME="/home/webchain"
RUN curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
RUN touch ~/.bashrc && chmod +x ~/.bashrc
#RUN git clone http://github.com/creationix/nvm.git /home/webchain/.nvm
RUN export NVM_DIR="$HOME/.nvm"
#RUN chmod -R 777 /home/webchain
RUN \. $HOME/.nvm/nvm.sh
RUN \. $HOME/.nvm/bash_completion
RUN bash -i -c 'nvm install v8.17.0'
RUN bash -i -c 'command -v nvm'

RUN wget https://github.com/mintme-com/webchaind/releases/download/v0.8.0/webchaind-0.8.0-linux-amd64.zip
RUN unzip webchaind-0.8.0-linux-amd64.zip -d .
#USER root
#RUN ls -la
#RUN \. webchain --help

#creation frontend
RUN git clone https://github.com/mintme-com/pool.git && mv pool webchain-pool
WORKDIR $HOME/webchain-pool
RUN make

WORKDIR $HOME/webchain-pool/www
RUN bash -i -c "npm install -g ember-cli@2.4.3"
RUN bash -i -c "npm install -g bower"
RUN bash -i -c "npm install"
RUN bash -i -c "bower install"
RUN ls -la
RUN chmod 777 ./build.sh
RUN \. ./build.sh

#RUN ls -la $HOME
#RUN ls -la $HOME/webchain-pool/
#RUN rm $HOME/webchain-pool/config.json
COPY ./config-json/config*json $HOME/webchain-pool/
#COPY ./config-json/config-api.json $HOME/webchain-pool/
#COPY ./config-json/config-unlocker.json $HOME/webchain-pool/
#COPY ./config-json/config-payouts.json $HOME/webchain-pool/
#RUN ls -la $HOME/webchain-pool

#my server 147.135.153.118
RUN sed -i 's/\/\/\example.net\//http:\/\/147.135.153.118\//' ./config/environment.js && \
    sed -i 's/example.net/http:\/\/147.135.153.118\//' ./config/environment.js

#copy initial script
EXPOSE 8080 80 39573 22 6379 68 31140
#CMD [ "$HOME/startallskiff.sh","start" ]
RUN ls -la /
#ENTRYPOINT [ "/startallskiff.sh" ]
#CMD ["nginx", "-g", "daemon off;"]
#CMD ["nginx","start"]
USER root
COPY ./startallskiff.sh /startallskiff.sh
RUN chmod 777 /startallskiff.sh

#copy wallet
COPY mainnet/keystore/* $HOME/.webchain/mainnet/keystore/
COPY wallet.pass $HOME/
RUN chown webchain:webchain /home/webchain/wallet.pass

#RUN chown webchain:webchain /startallskiff
RUN chown -R webchain:webchain $HOME/.webchain
RUN apt-get install nano
RUN . /startallskiff.sh
#ENTRYPOINT nginx -g 'daemon off;'
#CMD ["nginx", "-g", "daemon off;"]
#ENTRYPOINT ["\. /home/webchain/geth", "--mintme"]
#CMD ["nginx", "-g", "daemon off;"]
CMD /home/webchain/geth --mintme