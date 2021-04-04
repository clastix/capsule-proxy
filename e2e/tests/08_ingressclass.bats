#!/usr/bin/env bats

load "$BATS_TEST_DIRNAME/../libs/tenants_utils.bash"
load "$BATS_TEST_DIRNAME/../libs/poll.bash"
load "$BATS_TEST_DIRNAME/../libs/namespaces_utils.bash"
load "$BATS_TEST_DIRNAME/../libs/ingressclass_utils.bash"

setup() {
  create_tenant ingressclass alice
  kubectl patch tenants.capsule.clastix.io ingressclass --type=json -p '[{"op": "add", "path": "/spec/ingressClasses", "value": {"allowed": ["custom"], "allowedRegex": "\\w+-lb"}}]'
}

teardown() {
  delete_tenant ingressclass

  delete_ingressclass custom || true
  delete_ingressclass external-lb || true
  delete_ingressclass internal-lb || true
}

@test "Ingress Class retrieval via kubectl" {
  if [[ $(kubectl version -o json | jq -r .serverVersion.minor) -lt 18 ]]; then
    kubectl version
    skip "IngressClass resources is not suported on Kubernetes < 1.18"
  fi

  poll_until_equals "no IngressClass" "" "KUBECONFIG=${HACK_DIR}/alice.kubeconfig kubectl get ingressclasses.networking.k8s.io --output=name" 3 5

  local version="v1"
  if [[ $(kubectl version -o json | jq -r .serverVersion.minor) -lt 19 ]]; then
    version="v1beta1"
  fi
  create_ingressclass "${version}" custom
  create_ingressclass "${version}" external-lb
  create_ingressclass "${version}" internal-lb

  local list="ingressclass.networking.k8s.io/custom
ingressclass.networking.k8s.io/external-lb
ingressclass.networking.k8s.io/internal-lb"
  poll_until_equals "IngressClass retrieval" "$list" "KUBECONFIG=${HACK_DIR}/alice.kubeconfig kubectl get ingressclasses.networking.k8s.io --output=name" 3 5
}
