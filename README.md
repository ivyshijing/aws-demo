# aws-demo
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

#AWS VPC Setup

1. create VPC
2. create public-subnet
3. create private-subnet
4. create EIP
5. setup NAT gateway
6. init EC2 instance
7. bind EIP to EC2 instance

#Nginx setup by Ansible playbook

1. install ansible
2. ssh-keygen
3. set inventory file /etc/ansible/hosts
4. prepare nginx roles files
5. write playbook file nginx.yml
6. run ansible-playbook

#Cosmos setup

1. prepare shell script for cosmos install steps
2. run script
