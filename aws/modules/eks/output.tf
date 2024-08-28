##############################################################################
# COPYRIGHT Ericsson 2019
#
# The copyright to the computer program(s) herein is the property of
# Ericsson Inc. The programs may be used and/or copied only with written
# permission from Ericsson Inc. or in accordance with the terms and
# conditions stipulated in the agreement/contract under which the
# program(s) have been supplied.
##############################################################################

# output definition to get configuration for Authorizing worker nodes and
# seting up workstation KUBECONFIG

locals {
  config-map-aws-auth = <<CONFIGMAPAWSAUTH
apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.worker.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG
apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.enm.endpoint}
    certificate-authority-data: ${aws_eks_cluster.enm.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${local.cluster-name}"
KUBECONFIG

  worker_nodes = <<WORKERS
#!/usr/bin/env bash

set -x
set -e

kubectl --kubeconfig ~/.kube/${local.cluster-name} get nodes --no-headers; ret=$?
if [[ $ret -ne 0 ]]; then
  echo "Error: Kubectl can not connect"
  exit $ret
fi


status=1
count=0
while [[ $count -lt 120 && $status -ne 0 ]]; do
  echo "INFO: Waiting for worker nodes..."
  status=$(kubectl --kubeconfig ~/.kube/${local.cluster-name} get nodes --no-headers | awk  '{print $2}' | grep -c -v -w "Ready"|| true)
  ((count=count+1))
  sleep 3
done
if [[ $count -lt 120 ]]; then
  echo "INFO: Worker nodes joined successfully"
else
  echo "ERROR: Worker nodes could not join the cluster."
fi
WORKERS

  tiller = <<TILLER
#!/usr/bin/env bash

set -x
set -e

kubectl --kubeconfig ~/.kube/${local.cluster-name} get nodes --no-headers; ret=$?
if [[ $ret -ne 0 ]]; then
  echo "Error: Kubectl can not connect"
  exit $ret
fi

echo "INFO: Creating the tiller serviceaccount ...";
kubectl --kubeconfig ~/.kube/${local.cluster-name} -n kube-system create serviceaccount tiller;  ret=$?
if [[ $ret -ne 0 ]]; then
  echo "Error: Tiller serviceaccount could not be created"
  exit $ret
fi
echo "INFO: Binding the tiller serviceaccount to the cluster-admin role ...";
kubectl --kubeconfig ~/.kube/${local.cluster-name} create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount=kube-system:tiller ; ret=$?
if [[ $ret -ne 0 ]]; then
  echo "Error: clusterrolebinding for tiller could not be created"
  exit $ret
fi
echo "INFO: Installing tiller on EKS ...";
if [ -d ~/.helm/ ]; then
  rm -rf ~/.helm/
fi

helm --kubeconfig ~/.kube/${local.cluster-name} init --service-account tiller --upgrade --wait

status=1
count=0
while [[ $count -lt 120 && $status -ne 0 ]]; do
  echo "INFO: Waiting for worker nodes..."
  status=$(kubectl --kubeconfig ~/.kube/${local.cluster-name} get pod -l name=tiller -n kube-system --no-headers | awk '{print $3}' | grep -c -v -w "Running" || true)
  ((count=count+1))
  sleep 10
done
if [[ $count -lt 120 ]]; then
  echo "INFO: tiller pod is ready now."

  echo "INFO: Installing helm chart."
  helm --kubeconfig ~/.kube/${local.cluster-name} install --name=guestbook ${path.cwd}/charts/guestbook
else
  echo "ERROR: tiller pod is not ready after retries, so chart could not be installed."
fi
TILLER

}

output "config-map-aws-auth" {
  value = "${local.config-map-aws-auth}"
}

output "kubeconfig" {
  value = "${local.kubeconfig}"
}

output "cluster-name" {
  value = "${local.cluster-name}"
}

output "kubeconfig-path" {
  value = "~/.kube/${local.cluster-name}"
}
