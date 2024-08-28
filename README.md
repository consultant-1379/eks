# Terraform template for EKS 

Provision an EKS cluster on AWS for the ENM on public cloud project.

## Introduction

EKS module written in this template, provision the following resources:

1. EKS cluster of master nodes that is able to communicate with worker nodes.
2. IAM Role and Instance Profile for having access to the AWS services.
3. Security Groups, Rules, Route Tables and Route Table Associations for EKS workers to allow networking traffic.
4. AutoScaling Group with Launch Configuration to launch worker instances.
5. Worker Nodes in a private Subnet.
6. VPC for logically isolated network between EKS resources.
7. Internet Gateway (IGW) to allow interaction with internet.
9. The ConfigMap template to register workers with EKS.
10. KUBECONFIG file to authenticate kubectl.

## Usage

### kubectl - the command line K8s tool

#### install _kubectl_ & _aws-iam_authenticator_ & helm
* kubectl
  * on RH based Linux: ```sudo dnf install kubernetes-client```
    * check: ```kubectl version --short --client```
  * on linux , open a terminal :
  ```
  curl -o kubectl https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-06-05/bin/linux/amd64/kubectl
  chmod +x ./kubectl
  sudo mkdir $HOME/bin && mv kubectl /usr/local/bin/
  echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc
  source ~/.bashrc
  ```
    * check: ```kubectl version --short --client```

* aws-iam-authenticator
  * on Linux:
  ```
  curl -o aws-iam-authenticator https://amazon-eks.s3-us-west-2.amazonaws.com/1.11.5/2018-12-06/bin/linux/amd64/aws-iam-authenticator   
  chmod +x ./aws-iam-authenticator
  sudo mv aws-iam-authenticator /usr/local/bin/
  ```
    * Test: ```aws-iam-authenticator help```

  * on Windows, open a terminal emulator, preferrably MobaXterm:
  ```
  curl -k -# -o aws-iam-authenticator.exe  https://amazon-eks.s3-us-west-2.amazonaws.com/1.10.3/2018-07-26/bin/windows/amd64/aws-iam-authenticator.exe
  chmod +x aws-iam-authenticator.exe
  mv aws-iam-authenticator.exe $HOME/bin
  ```
    * Test: ```aws-iam-authenticator.exe help```

* Helm
    ```
    cd ~/environment   # create a directory first with a name of your preference - for example here environment. 
    curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
    chmod +x get_helm.sh
    ./get_helm.sh
    ```
* aws credentials (ACCESS KEY+SECRET)

   Provide your aws access key+secret and put them into the credentials template
    * populate aws credentials file
      by simply executing ```aws configure``` command and providing credentials 
      or copy the information in the file named _credentials_ to
      * WINDOWS cygwin: ```mkdir $HOMEPATH/.aws && vi $HOMEPATH/.aws/credentials```
      * Linux: ```mkdir ~/.aws; vi ~/.aws/credentials```
      and set the properties _aws_access_key_id_ and _aws_secret_access_key_
      * Here is a template for ```~/.aws/credentials``` file:
        ```
        [default]
        aws_access_key_id = YOUR_ACCESS_KEY
        aws_secret_access_key = YOUR_SECRET_KEY
        ```

#### configure _kubectl_
In this step a configuration file for the binary ```kubectl``` is created, which is the main tool to interact with Kubernetes later on.
* Create .kube directory as a place to store you kubectl configuration file :
  * Linux: ```mkdir ~/.kube```
  * Windows (cygwin): ```mkdir $HOMEPATH/.kube```
  
* It is not necessary to have some pre-configured config file at this moment as config file for kubectl will be generated
  by the terraform.

* as kubectl configuration will be generated in ```~/.kube``` directory, you could reference it by exporting KUBECONFIG environment variable:   
* Linux : ```export KUBECONFIG=~/.kube/kube-config-eks```
  Windows : ```export KUBECONFIG=$HOMEPATH/.kube/kube-config-eks```

* Test connectivity and access:  
  ```
  #>kubectl get svc
  NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
  kubernetes   ClusterIP   xxxxxxxxx    <none>        443/TCP   4m
  ```
  command to check the config for kubectl: `kubectl config view`

The communication to K8s control pane on AWS is successfully performed.

#### Component parameters
The configuration could be updated with the following input variables:

| Name                 | Description                       | Default              |
|-----------------------|-----------------------------------|---------------------|
| `environment-name`    | name of provisioning environment  | `production`        |
| `enm-eks`             | name of component                 | `enm-eks`           |
| `cluster-name`        | The name of the EKS cluster       | `ericsson`          |
| `aws-region`          | The AWS region to deploy EKS      | `eu-west-1`         |
| `kubernetes-version`  | kubernetes version to launch      | `1.11`              |
|`worker-instance-type` | Worker Node EC2 instance type     | `t3.medium`         |
| `desired-capacity`    | Autoscaling desired node capacity | `2`                 |
| `max-size`           | Autoscaling Maximum node capacity  | `5`                 |
| `min-size`           | Autoscaling Minimum node capacity  | `1`                 |
| `vpc-subnet-cidr`    | Subnet CIDR                        | `10.0.0.0/16`       |
| `key-name`           | SSH public key                     | `enm-eks-key`       |
| `public-key`         | Public key filename                | `~/.ssh/id_rsa.pub` |


> A file 'terraform.tfvars' could be created in the project root directory to place custom variables if there is a need to override the defaults.

## How to use this component


Clone the project repository and follow the steps :

```bash
cd eks/path_to_the_required_component           # in case of eks component -> cd eks/aws/environment/production/eks
```

To view the plan in the deployment, while you are in the a component path execute :

```bash
terraform plan
```

And to apply the plan:

```bash
terraform apply
```
### IAM

The AWS credentials must be associated with a user having at least the following AWS managed IAM policies

* IAMFullAccess
* AutoScalingFullAccess
* AmazonEKSClusterPolicy
* AmazonEKSWorkerNodePolicy
* AmazonVPCFullAccess
* AmazonEKSServicePolicy
* AmazonEKS_CNI_Policy
* AmazonEC2FullAccess

In addition, the following managed policies should be created:

*EKS*

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        }
    ]
}
```


### Setup kubectl

Setup the `KUBECONFIG`

```bash
terraform output kubeconfig > ~/.kube/eks-cluster
export KUBECONFIG=~/.kube/eks-cluster
```

### Authorize worker nodes

Get the config from terraform output, and save it to a yaml file:

```bash
terraform output config-map > config-map-aws-auth.yaml
```

Apply the config map to EKS:

```bash
kubectl apply -f config-map-aws-auth.yaml
```

To verify whether the worker nodes joined the cluster:

```bash
kubectl get nodes --watch
```

### Instruction on helm

You can watch the status of by running:

```
kubectl get svc -w {{ your release name }} --namespace {{ your release namespace }}
```
To retrieve hostname property from kubernetes service you could run:
```
export SERVICE_HOST=$(kubectl get svc --namespace {{ .Release.Namespace }} {{ include "guestbook.fullname" . }} -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
```
to reach the release you could run:
```
echo http://SERVICE_HOST:{{ your app port }}
```

### persistent volume
In AWS EKS a persistent volume (PV) is implemented via a EBS volume, which has to be declared as a _storage class_ first.
A stateful app can then request a volume, by specifying a _persistent volume claim_ (PVC) and mount it in its corresponding pod.

1. Define a storage class:
```
kubectl apply -f gp2-storage-class.yaml --namespace=enm-eks-app
```
set this storage class as **default**
check the current state:
```
kubectl get storageclasses --namespace=enm-eks-app
```
set default:
```
kubectl patch storageclass gp2 -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' --namespace=enm-eks-app
```
To check the state:
```
kubectl get storageclasses --namespace=enm-eks-app
```
2. Define a persistent volume claim:
```
kubectl apply -f pvcs.yaml --namespace=enm-eks-app
```
and check:
```
kubectl get pvc --namespace=enm-eks-app
```
For more references: 
   
    3- Storage Classes:                 https://docs.aws.amazon.com/eks/latest/userguide/storage-classes.html
    2- Amazon EBS Volume Types:         https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/EBSVolumeTypes.html
    1- Using Persistent Volumes on AWS: https://docs.giantswarm.io/guides/using-persistent-volumes-on-aws/

### Cleaning up

The created cluster can be destroyed entirely by executing the following commands:

```bash
terraform plan -destroy
terraform destroy  --force
```
