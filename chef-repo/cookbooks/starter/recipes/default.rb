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
