# EC2 with chef, knife and chef-client<br>

![](/images/04-image01.png)

This blog was inspired with few Infrastructure as Code available on market. <br>
From below, Chef & Ansible are not ideally aiming for IaC, but still possible.<br>

| Tool           | Purpose                                      | Language   | Configuration Management | Infrastructure as Code | Agent-based |
|----------------|----------------------------------------------|------------|--------------------------|------------------------|-------------|
| Terraform      | Infrastructure provisioning and management   | HashiCorp  | Yes                      | Yes                    | No          |
| Ansible        | Configuration management and automation      | Python     | Yes                      | No                     | No          |
| CloudFormation | Infrastructure provisioning and management   | AWS        | Yes                      | Yes                    | No          |
| Chef           | Configuration management and automation      | Ruby       | Yes                      | No                     | Yes         |
| Puppet         | Configuration management and automation      | Ruby       | Yes                      | No                     | Yes         |
| Salt           | Configuration management and automation      | Python     | Yes                      | No                     | Yes         |

I will introduce some kind of knowledge I learn from [Angelie](https://www.youtube.com/watch?v=04oITjdLtho) from Simplilearn <br>
and [John Tonello](https://www.youtube.com/watch?v=lqMijB1JIuU) from Progress Chef as their video were amazing for beginners. <br>

## CHEF INSTALLATION
As Progress announced and completed Chef acquisition in September-October 2020,<br>
few resources for installation may change. Herewith the one I use by early 2024.<br>

```sh
wget https://packages.chef.io/files/stable/chef-workstation/21.2.278/ubuntu/20.04/chef-workstation_21.2.278-1_amd64.deb
sudo dpkg -i chef-workstation_21.2.278-1_amd64.deb
```

Check the successful installation through chef --version command which show like<br>
```sh
Chef Workstation version: 21.2.278
Chef Infra Client version: 16.10.8
Chef InSpec version: 4.26.4
Chef CLI version: 3.1.1
Chef Habitat version: 1.6.181
Test Kitchen version: 2.10.0
Cookstyle version: 7.8.0
``` 
As above table mentioned, Chef is an Agent-based in this case a cloud based.<br>
You may see https://api.chef.io/organizations/beamdata that I setup earlier. <br>

Herewith is configuration example you got when you download a starter kit.<br>
![](/images/04-image02.png)
As soon as you hit Starter Kit, it will bring you to this page
![](/images/04-image03.png)
If this for your first time, you may neglect this. Otherwise you need to <br>
update your pem key afterwads in your system to reach this portal again.
![](/images/04-image04.png)

Normally you will get chef-starter.zip and could simply unzip it like below

```sh
unzip chef-starter.zip
```

It would create a new folder chef-repo with sample and pem files like below.<br>
```sh
── chef-repo
│   ├── .chef
│   │   ├── config.rb
│   │   └── farius.pem
│   ├── cookbooks
│   │   ├── chefignore
│   │   └── starter
│   │       ├── attributes
│   │       │   └── default.rb
│   │       ├── files
│   │       │   └── default
│   │       │       └── sample.txt
│   │       ├── metadata.rb
│   │       ├── recipes
│   │       │   └── default.rb
│   │       └── templates
│   │           └── default
│   │               └── sample.erb
│   ├── .gitignore
│   ├── README.md
│   └── roles
│       └── starter.rb
└── chef-starter.zip
```
Take a look at these two files for example (farius.pem and default.rb). <br>

```sh
── chef-repo
│   ├── .chef
│   │   └── farius.pem
│   └── cookbooks
│       ├── chefignore
│       └── starter
│           └── recipes
│             └── default.rb
└── chef-starter.zip
```
If you setup Chef account correctly (it's free) the may ask for a username. <br>
At that case I selected my name, that's the reason I got pem file like this.<br>
It looks like AWS pem file you created from AWS console and should look like<br>

```ssh

-----BEGIN RSA PRIVATE KEY-----
MIIEp...
               ...
                        ...4Wis=
-----END RSA PRIVATE KEY-----

```
For the Ruby file, this is where Chef will receive instruction to configre. <br>
By default the default.rb file would look like below<br>

```sh
root@msi:/home/devops/test/chef-repo/cookbooks/starter/recipes# cat default.rb
# This is a Chef Infra recipe file. It can be used to specify resources which will
# apply configuration to a server.

log "Welcome to Chef Infra, #{node["starter_name"]}!" do
  level :info
end
```
If everything was setup properly and when you type  

```sh
knife cookbook upload starter
```

you would get a new policy listed/updated like below.
![](/images/04-image05.png)

Question is, how do we need to setup the connection correctly?<br>
This is an example of initial connection setup with knife configure.<br>

```sh
root@msi:/home/devops/test/chef-repo/cookbooks# knife configure init-config
Please enter the chef server URL: [https://msi/organizations/myorg] https://api.chef.io/organizations/beamdata
Please enter an existing username or clientname for the API: [devops] farius
Overwrite /root/.chef/credentials? (Y/N) Y
*****

You must place your client key in:
  /root/.chef/farius.pem
Before running commands with Knife

*****
Knife configuration file written to /root/.chef/credentials
root@msi:/home/devops/test/chef-repo/cookbooks# cat /root/.chef/credentials
[default]
client_name     = 'farius'
client_key      = '/root/.chef/farius.pem'
chef_server_url = 'https://api.chef.io/organizations/beamdata'
root@msi:/home/devops/test/chef-repo/cookbooks# knife cookbook upload starter
Uploading starter        [1.0.0]
Uploaded 1 cookbook.
root@msi:/home/devops/test/chef-repo/cookbooks# 
```
From you Chef account you can enter your chef server URL.<br>
In my case it would be https://api.chef.io/organizations/beamdata<br>
In case there is an error knife config cannot locate the cookbook path<br>
, refer to John video (1:53-1:56) to add a new line to locate manually.<br>

In this we will not run a node and run the policy there but just to<br>
run the ruby command locally to spin new EC2 instance.

## EC2 with Ruby

At the end we will contruct ruby command like below to spin an EC2.

```sh
# This is a Chef Infra recipe file. It can be used to specify resources which will
# apply configuration to a server.

log 'Hello, Welcome to Chef Infra!' do
  level :info
end

execute 'echo_command' do
command <<-EOH
  aws ec2 run-instances \
    --image-id ami-0fc5d935ebf8bc3bc \
    --instance-type t2.micro \
    --key-name wcd-project \
    --subnet-id $( \
        aws ec2 describe-subnets \
          --filters 'Name=default-for-az,Values=false' \
          --query 'Subnets[].SubnetId' --output text) \
    --security-group-ids $( \
        aws ec2 describe-security-groups \
          --filters Name=vpc-id,Values=vpc-0c98836a563def916 \
          --query 'SecurityGroups[?Description!= \ 
              `default VPC security group`].GroupId' --output text) \
    --associate-public-ip-address \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=node}]' \
    > /dev/null
  EOH
  action :run
end
```
which is similar with cli command below you can run on ubuntu<br>

```sh
#!/bin/bash
aws ec2 run-instances --image-id ami-0fc5d935ebf8bc3bc \
--instance-type t2.micro \
--key-name wcd-project \
--subnet-id $( \ 
-- aws ec2 describe-subnets \
	--filters 'Name=default-for-az,Values=false' \
	--query 'Subnets[].SubnetId' --output text) \
--security-group-ids $( \
-- aws ec2 describe-security-groups \
	--filters Name=vpc-id,Values=vpc-0c98836a563def916 \
	--query 'SecurityGroups[?Description!=`default VPC security group`].GroupId' --output text) \
--associate-public-ip-address \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=node}]' > /dev/null

```
For simplicity, I setup new VPC, subnet, internet gateway, <br>
route table, security groups with Terraform for test purpose.<br>

```txt
provider "aws" {
  region     = "us-east-1"
  access_key = jsondecode(file("aws.credentials")).access
  secret_key = jsondecode(file("aws.credentials")).secret
}

resource "aws_vpc" "vpc-project6" {
    cidr_block = "10.2.0.0/16"
    tags = {
    Name = "vpc-project6"
    }
}

resource "aws_subnet" "pub-subnet" {
    vpc_id = aws_vpc.vpc-project6.id
    cidr_block = "10.2.254.0/24"
    tags = {
    Name = "pub-subnet"
    }
}

resource "aws_internet_gateway" "igw-vpc-project6" {
    vpc_id = aws_vpc.vpc-project6.id
    tags = {
    Name = "igw-vpc-project6"
    }
}

resource "aws_route_table" "rt-pub-project6" {
vpc_id = aws_vpc.vpc-project6.id
route {
cidr_block = "0.0.0.0/0"
gateway_id = aws_internet_gateway.igw-vpc-project6.id
}
tags = {
Name = "rt-pub-project6"
}
}

resource "aws_route_table_association" "rt-pub_association-project6" {
    subnet_id = aws_subnet.pub-subnet.id
    route_table_id = aws_route_table.rt-pub-project6.id
}

resource "aws_security_group" "sg_api_project6" {
  name        = "sg_api_project6"
  description = "sg_api_project6"
  vpc_id      = aws_vpc.vpc-project6.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }  

  tags = {
    Name = "sg_api_project6"
  }
}

```
You can skip above process if you want to use old resources and<br>
know how to call/distinguish which resource to call to build EC2.<br>

Assuming we have the rb file inside starter cookbook, we can then<br>
launch new EC2 with chef-client command (instead of using node)

```sh
sudo chef-client -zr starter
```

Herewith the entire process

```sh
root@msi:/home/devops/chef-repo/cookbooks/starter/recipes# sudo chef-client -zr starter
[2024-01-20T11:09:56-05:00] INFO: Started Chef Infra Zero at chefzero://localhost:1 with repository at /home/devops/chef-repo (One version per cookbook)
Starting Chef Infra Client, version 16.10.8
Patents: https://www.chef.io/patents
[2024-01-20T11:09:56-05:00] INFO: *** Chef Infra Client 16.10.8 ***
[2024-01-20T11:09:56-05:00] INFO: Platform: x86_64-linux
[2024-01-20T11:09:56-05:00] INFO: Chef-client pid: 416401
[2024-01-20T11:09:57-05:00] INFO: Setting the run_list to [#<Chef::RunList::RunListItem:0x0000000001b88d68 @version=nil, @type=:recipe, @name="starter">] from CLI options
[2024-01-20T11:09:57-05:00] INFO: Run List is [recipe[starter]]
[2024-01-20T11:09:57-05:00] INFO: Run List expands to [starter]
[2024-01-20T11:09:57-05:00] INFO: Starting Chef Infra Client Run for farius
[2024-01-20T11:09:57-05:00] INFO: Running start handlers
[2024-01-20T11:09:57-05:00] INFO: Start handlers complete.
resolving cookbooks for run list: ["starter"]
[2024-01-20T11:09:57-05:00] INFO: Loading cookbooks [starter@1.0.0]
Synchronizing Cookbooks:
[2024-01-20T11:09:57-05:00] INFO: Storing updated cookbooks/starter/recipes/default.rb in the cache.
  - starter (1.0.0)
Installing Cookbook Gems:
Compiling Cookbooks...
Converging 2 resources
Recipe: starter::default
  * log[Hello, Welcome to Chef Infra!] action write[2024-01-20T11:09:57-05:00] INFO: Processing log[Hello, Welcome to Chef Infra!] action write (starter::default line 4)
[2024-01-20T11:09:57-05:00] INFO: Hello, Welcome to Chef Infra!

  * execute[echo_command] action run[2024-01-20T11:09:57-05:00] INFO: Processing execute[echo_command] action run (starter::default line 8)
[2024-01-20T11:10:02-05:00] INFO: execute[echo_command] ran successfully

    - execute 
     aws ec2 run-instances   --image-id ami-0fc5d935ebf8bc3bc   --instance-type t2.micro   --key-name wcd-project   --subnet-id $(   aws ec2 describe-subnets     --filters 'Name=default-for-az,Values=false'     --query 'Subnets[].SubnetId' --output text)   --security-group-ids $(    aws ec2 describe-security-groups     --filters Name=vpc-id,Values=vpc-0c98836a563def916     --query 'SecurityGroups[?Description!=`default VPC security group`].GroupId' --output text)   --associate-public-ip-address   --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=node}]' > /dev/null
  
[2024-01-20T11:10:02-05:00] INFO: Chef Infra Client Run complete in 4.995065022 seconds

Running handlers:
[2024-01-20T11:10:02-05:00] INFO: Running report handlers
Running handlers complete
[2024-01-20T11:10:02-05:00] INFO: Report handlers complete
Chef Infra Client finished, 1/2 resources updated in 06 seconds
[2024-01-20T11:10:03-05:00] WARN: This release of Chef Infra Client became end of life (EOL) on May 1st 2022. Please update to a supported release to receive new features, bug fixes, and security updates.

```
<br>

## SUMMARY
According to [João-longo](https://www.encora.com/insights/differences-between-infrastructure-as-code-iac-tools-used-for-provisioning-and-configuration-management) IaC tools cited into two categories<br>

```txt

1. Provisioning – tools in this category provision infrastructure
   components for one or more cloud providers. Examples: Terraform,
   AWS CloudFormation, and Pulumi 

2. Configuration Management – tools in this category are responsible
   for installing and managing software on already existing infrastructure.
   Examples: Ansible, Chef, and Puppet 

```
Considering a project has two main phases: initial setup and <br>
maintenance, all tools can be used in both. Combining the <br>
categories discussed above (provisioning and configuration <br>
management) with these two project phases (initial setup and <br>
maintenance), a table can be derived, containing the description <br>
and the most used tool in each cell as shown below. 

![](/images/04-image06.png)
