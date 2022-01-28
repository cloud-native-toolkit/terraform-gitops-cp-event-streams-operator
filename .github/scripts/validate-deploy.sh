#!/usr/bin/env bash

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)
BIN_DIR=$(cat .bin_dir)

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE="openshift-operators"
BRANCH="main"
SERVER_NAME="default"
TYPE="base"
LAYER="2-services"

COMPONENT_NAME="ibm-eventstreams"

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

if [[ ! -f "./argocd/2-services/cluster/default/operators/${NAMESPACE}-ibm-eventstreams-operator.yaml" ]]; then
  echo "ArgoCD config missing - ./argocd/2-services/cluster/default/operators/${NAMESPACE}-ibm-eventstreams-operator.yaml"
  exit 1
fi

echo "Printing argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
cat "./argocd/2-services/cluster/default/operators/${NAMESPACE}-ibm-eventstreams-operator.yaml"

if [[ ! -f "./payload/2-services/namespace/${NAMESPACE}/ibm-eventstreams-operator/values.yaml" ]]; then
  echo "Application values not found - ./payload/2-services/namespace/${NAMESPACE}/ibm-eventstreams-operator/values.yaml"
  exit 1
fi

echo "Printing ./payload/2-services/namespace/${NAMESPACE}/ibm-eventstreams-operator/values.yaml"
cat "./payload/2-services/namespace/${NAMESPACE}/ibm-eventstreams-operator/values.yaml"

count=0
until kubectl get namespace "${NAMESPACE}" 1> /dev/null 2> /dev/null || [[ $count -eq 20 ]]; do
  echo "Waiting for namespace: ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for namespace: ${NAMESPACE}"
  exit 1
else
  echo "Found namespace: ${NAMESPACE}. Sleeping for 30 seconds to wait for everything to settle down"
  sleep 30
fi


SUBSCRIPTION="subscription/${COMPONENT_NAME}"
count=0
until kubectl get "${SUBSCRIPTION}" -n "${NAMESPACE}" || [[ $count -eq 20 ]]; do
  echo "Waiting for ${SUBSCRIPTION} in ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for ${SUBSCRIPTION} in ${NAMESPACE}"
  kubectl get subscription -n "${NAMESPACE}"
  exit 1
fi

count=0
until kubectl get csv -n "${NAMESPACE}" -o json | "${BIN_DIR}/jq" -r '.items[] | .metadata.name' | grep -q ibm-eventstreams || [[ $count -eq 20 ]]; do
  echo "Waiting for ibm-eventstreams csv in ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for ibm-eventstreams csv in ${NAMESPACE}"
  kubectl get csv -n "${NAMESPACE}"
  exit 1
fi

CSV=$(kubectl get csv -n "${NAMESPACE}" -o json | "${BIN_DIR}/jq" -r '.items[] | .metadata.name' | grep ibm-eventstreams)
echo "Found csv ${CSV} in ${NAMESPACE}"

cd ..
rm -rf .testrepo
