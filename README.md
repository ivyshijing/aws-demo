Cosmos service deploy on AWS Cloud ENV
======
Usage:
------
```
    1. start cosmos service
       * ssh -i $keyfile ubuntu@18.140.29.205 -p 8090
       * ~/go/bin/cosmos_start.sh
    2. GET http://18.140.29.205:26657

```
Features realized:
1. API call nginx 26657 port to access cosmos service
   
   GET http://18.140.29.205:26657

2. SSH call nginx 8090 port to login cosmos server

   ssh -i keyfile ubuntu@18.140.29.205 -p 8090

Deploy Steps：
-----

#### AWS VPC Setup

1. create VPC
   ```
    set IPv4 CIDR block: 10.0.0.0/16
   ```
2. create two subnet
   ```
    IPv4 CIDR block: 10.0.0.0/20
    IPv4 CIDR block: 10.0.17.0/20 
   ```
3. config 10.0.0.0/20 as public-subnet
   ```
    * create a internet gateway
    * create a route table for VPC 10.0.0.0/16
    * config the route table, add a entry routes make all other IPv4 subnet traffic to the Internet gateway
      Destination	Target
      10.0.0.0/16       local
      0.0.0.0/0         igw-id
    * on the public subnet associate the above route table
   ``` 
4. create security group
   ```
    * public-subnet bind security group: open port 22,80,8090,26657 
    * private-subnet bind security group: open port 22,80,6060,26656-26660 
   ```
5. init three EC2 instance
   ```
    * init 2 instance in the public-subnet:
       ansible EC2 instance
       nginx EC2 instance
    * init 1 instance in the private-subnet:
       cosmos server EC2 instance
    * bind security group when create EC2 instance
   ```
6. create two EIP and bind to ansible and nginx EC2 instance 
7. setup NAT gateway
   ```
    * create a NAT gateway in public-subnet and bind the EIP to it
    * create a new route table bind to the private-subnet
       Destination       Target
       10.0.0.0/16       local
       0.0.0.0/0         NAT-id
   ```

#### Nginx setup by Ansible playbook

1. install ansible
    ```
    sudo apt update
    sudo apt install software-properties-common
    sudo apt-add-repository ppa:ansible/ansible
    sudo apt update
    sudo apt install ansible
    ```

2. Configure confidential login between hosts
    ```
    * gennerate ssh public and private keys on the ansible server
       ssh-keygen -t rsa

    * copy public key content to file '.ssh/authorized_keys' on client hosts
       
    ```
     
3. set inventory file /etc/ansible/hosts
    ```
    [nginxserver]
    10.0.13.101
    ```

4. prepare nginx roles files
    ```
     tree in roles:
     └── nginx
        ├── default
        ├── files
        │   └── nginx-1.17.5.tar.gz
        ├── handlers
        ├── meta
        ├── tasks
        │   └── main.yml
        ├── templates
        │   ├── nginx.conf.j2
        └── vars

    ```
    ```
     tasks/main.yml:
     - name: copy nginx
       copy: src=nginx-1.17.5.tar.gz dest=/tmp/

     - name: apt update
       apt:
          upgrade: yes
          update_cache: yes

     - name: apt-get build-essential libtool libpcre3 libpcre3-dev zlib1g-dev openssl libssl-dev
       apt:
          name: "{{ packages }}"
       vars:
          packages:
          - build-essential
          - libtool
          - libpcre3
          - libpcre3-dev
          - zlib1g-dev
          - openssl
          - libssl-dev

     - name: create nginx user and group
       shell: groupadd nginx; useradd -g nginx nginx

     - name: tar nginx
       shell: chdir=/tmp tar -zxf nginx-1.17.5.tar.gz

     - name: install nginx
       shell: chdir=/tmp/nginx-1.17.5 ./configure --user=nginx --group=nginx --with-stream  && make && make install

     - name: copy nginx.conf
       template: src=nginx.conf.j2 dest=/usr/local/nginx/conf/nginx.conf

     - name: open nginx
       shell: /usr/local/nginx/sbin/nginx
    ```
    ```
     templates/nginx.conf.j2:
      worker_processes  1;
      events {
         worker_connections  1024;
      }

      stream {

         server {
            listen 8090;
            proxy_pass 10.0.28.183:22;
         }

         server {
            listen 26657;
            proxy_pass 10.0.28.183:26657;
         }
      }
    ```
5. write playbook file nginx.yml
    ```
    - name: install nginx use roles nginx
      hosts: nginxserver
      remote_user: root
      roles:
      - nginx
    ```

6. run ansible-playbook
    ```
     ansible-playbook nginx.yml
    ```

#### Cosmos setup

###### Steps: 
        * install go, gaiad, gaiacli
        * config a full node

1. reference the cosmos.network website and other document from google,try the steps and write a shell script as below:
   ```
    setup.sh:

     #!/bin/bash

     GO_VERSION=go1.12.5
     COSMOS_VERSION=v0.35.0

     echo "update"
     sudo apt-get update
     sudo apt-get upgrade -y
     echo "Checking required packages are installed"
     sudo apt-get install -y wget git make gcc curl

     echo "Installing go"
     wget https://dl.google.com/go/$GO_VERSION.linux-amd64.tar.gz
     sudo tar -C /usr/local -xzf $GO_VERSION.linux-amd64.tar.gz
     rm $GO_VERSION.linux-amd64.tar.gz

     echo "Setting up environment variables for GO"

     mkdir -p $HOME/go/bin
     echo "export GOPATH=$HOME/go" >> ~/.bashrc
     echo "export GOBIN=\$GOPATH/bin" >> ~/.bashrc
     echo "export PATH=\$PATH:\$GOBIN:/usr/local/go/bin" >> ~/.bashrc
     source ~/.bashrc
     export GOPATH=$HOME/go
     export GOBIN=$GOPATH/bin
     export PATH=$PATH:$GOBIN:/usr/local/go/bin

     echo "Installing cosmos-sdk"

     mkdir -p $GOPATH/cosmos
     cd $GOPATH/cosmos
     git clone https://github.com/cosmos/cosmos-sdk
     cd cosmos-sdk && git checkout $COSMOS_VERSION
     make tools install

     #check the version 
     gaiad version --long
     gaiacli version --long
     
     #init a node
     echo "Setting up gaia service"
     gaiad init ivy

     # connect a testnet
     ### copy the Genesis File
     echo "Need genesis.json to connect to testnet"
     rm $HOME/.gaiad/config/genesis.json
     curl https://raw.githubusercontent.com/cosmos/launch/master/genesis.json > $HOME/.gaiad/config/genesis.json

     ### modify persistent_peer
     echo "Need to add persistent_peer in $HOME/.gaiad/config/config.toml before start"
   ```
2. modify config file to add persistent_peer
   ```
     config persistent_peers in the file $HOME/.gaiad/config.toml
     persistent_peers = "89e4b72625c0a13d6f62e3cd9d40bfc444cbfa77@34.65.6.52:26656"

   ```
3. prepare two shell script for service start and stop
    ```
     * start: $HOME/go/bin/cosmos_start.sh
      #!/bin/bash
      nohup gaiad start &>$HOME/gaiad.log &
 
     * stop: $HOME/go/bin/cosmos_stop.sh
      #!/bin/bash
      ps -ef | grep gaiad | grep -v grep | awk '{print $2}' | xargs -i kill -9 {}
    ```
