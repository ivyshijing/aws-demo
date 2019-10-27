Cosmos service deploy on AWS Cloud ENV
======
Usage:
------
Features realized:
1. API call nginx 26657 port to access cosmos service
   
   GET http://18.140.29.205:26657

2. SSH call nginx 8090 port to login cosmos server

   ssh -i keyfile 18.140.29.205 -p 8090

Deploy Steps：
-----

#### AWS VPC Setup

1. create VPC
2. create public-subnet
3. create private-subnet
4. create EIP
5. setup NAT gateway
6. init EC2 instance
7. bind EIP to EC2 instance

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

1. prepare shell script for cosmos install steps
2. run script
