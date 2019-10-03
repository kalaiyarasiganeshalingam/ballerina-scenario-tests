#!/bin/bash
# Copyright (c) 2019, WSO2 Inc. (http://wso2.org) All Rights Reserved.
#
# WSO2 Inc. licenses this file to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file except
# in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

readonly deployment_parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
readonly deployment_grand_parent_path=$(dirname ${deployment_parent_path})

. ${deployment_grand_parent_path}/common/usage.sh
. ${deployment_grand_parent_path}/setup/setup_deployment_env.sh

function setup_deployment() {
    clone_repo_and_set_bal_path
    deploy_unary_go_service
    replace_variables_in_bal_files
    build_and_deploy_grpc_client_resources
    wait_for_pod_readiness
    retrieve_and_write_properties_to_data_bucket
    local is_debug_enabled=${infra_config["isDebugEnabled"]}
    if [ "${is_debug_enabled}" = "true" ]; then
        print_kubernetes_debug_info
    fi
}

## Functions

function clone_repo_and_set_bal_path() {
    git clone https://github.com/ballerina-platform/ballerina-scenario-tests.git
    product_Info_client_bal_path=grpc/src/test/resources/grpc-scenarios/src/unsecured_unary_client/product_Info_client.bal
}

function deploy_unary_go_service() {
    docker login --username=${docker_user} --password=${docker_password}

    kubectl create -f grpc/src/test/resources/grpc-scenarios/src/unsecured_unary_client/resources/go-grpc-service.yaml
    wait_for_pod_readiness
    kubectl get svc
}

function print_kubernetes_debug_info() {
    kubectl get pods
    kubectl get svc ballerina-grpc-unary-client-proxy -o=json
    kubectl get nodes --output wide
}

function replace_variables_in_bal_files() {
    replace_variables_in_bal_file ${product_Info_client_bal_path}
}

function replace_variables_in_bal_file() {
    local bal_path=$1
    sed -i "s:<USERNAME>:${docker_user}:g" ${bal_path}
    sed -i "s:<PASSWORD>:${docker_password}:g" ${bal_path}
}

function build_and_deploy_grpc_client_resources() {
    cd grpc/src/test/resources/grpc-scenarios
    ${ballerina_home}/bin/ballerina build unsecured_unary_client
    kubectl apply -f ${work_dir}/grpc/src/test/resources/grpc-scenarios/target/kubernetes/unsecured_unary_client --namespace=${cluster_namespace}
}

function retrieve_and_write_properties_to_data_bucket() {
    local external_ip=$(kubectl get nodes -o=jsonpath='{.items[0].status.addresses[?(@.type=="ExternalIP")].address}')
    local node_port=$(kubectl get svc ballerina-grpc-unary-client-proxy -o=jsonpath='{.spec.ports[0].nodePort}')
    declare -A deployment_props
    deployment_props["ExternalIP"]=${external_ip}
    deployment_props["NodePort"]=${node_port}
    write_to_properties_file ${output_dir}/deployment.properties deployment_props
    local is_debug_enabled=${infra_config["isDebugEnabled"]}
    if [ "${is_debug_enabled}" = "true" ]; then
        echo "ExternalIP: ${external_ip}"
        echo "NodePort: ${node_port}"
    fi
}

setup_deployment
