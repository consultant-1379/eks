environment_name = "production"

component_name = "enm-eks"

profile = "default"

cluster-name = "ericsson"

aws-region = "eu-west-1"

kubernetes-version = "1.11"

vpc-subnet-cidr = "10.0.0.0/16"

worker-instance-type = "t3.medium"

desired-capacity = 2

max-size = 5

min-size = 1

key-name = "enm-eks-key"

public-key = "~/.ssh/id_rsa.pub"

