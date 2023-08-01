cidr_vpc = "10.0.0.0/16"
tags_vpc = {
  Name = "nginx-vpc"
}
tags_igw = {
  Name = "nginx-igw"
}
cidr_subnets = [ "10.0.1.0/24", "10.0.2.0/24" ]
az = [ "us-east-1a", "us-east-1b" ]
tags_sub1 = {
  Name = "nginx-sub1"
}
cidr_rt = "0.0.0.0/0"
tags_rt = {
  Name = "nginx-rt"
}
tags_sub2 = {
  Name = "nginx-sub2"
}
cidr_sg = [ "0.0.0.0/0" ]
ami_instance = "ami-053b0d53c279acc90"
ami_instance_type = "t3.medium"
tags_instance = {
  Name = "nginx-server"
}
