#Copyright 2018 The CDI Authors.
#
#Licensed under the Apache License, Version 2.0 (the "License");
#you may not use this file except in compliance with the License.
#You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
#Unless required by applicable law or agreed to in writing, software
#distributed under the License is distributed on an "AS IS" BASIS,
#WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#See the License for the specific language governing permissions and
#limitations under the License.

.PHONY: build build-controller build-importer build-cloner build-apiserver build-uploadproxy build-uploadserver build-operator build-functest-file-image-init build-functest-registry-image-init build-functest \
	    manifests \
    	docker docker-controller docker-cloner docker-importer docker-apiserver docker-uploadproxy docker-uploadserver docker-operator docker-functest-image-init docker-functest-image-http docker-functest-registry-populate docker-functest-registry docker-functest-registry-init \
		cluster-up cluster-down cluster-sync cluster-sync-controller cluster-sync-cloner cluster-sync-importer cluster-sync-apiserver cluster-sync-uploadproxy cluster-sync-uploadserver \
		test test-functional test-unit test-lint \
		publish \
		vet \
		format \
		goveralls \
		release-description

DOCKER=1
ifeq (${DOCKER}, 1)
DO=./hack/build/in-docker.sh
else
DO=eval
endif

all: manifests docker

clean:
	${DO} "./hack/build/build-go.sh clean; rm -rf bin/* _out/* manifests/generated/* .coverprofile release-announcement"

generate:
	${DO} "./hack/update-codegen.sh"

generate-verify:
	${DO} "./hack/verify-codegen.sh"

deps-update:
	${DO} "./hack/build/dep-update.sh"

apidocs:
	${DO} "./hack/update-codegen.sh && ./hack/gen-swagger-doc/gen-swagger-docs.sh v1alpha1 html"

build:
	${DO} "DOCKER_PREFIX=${DOCKER_PREFIX} DOCKER_TAG=${DOCKER_TAG} VERBOSITY=${VERBOSITY} PULL_POLICY=${PULL_POLICY} ./hack/build/build-go.sh clean && ./hack/build/build-go.sh build ${WHAT} && ./hack/build/build-cdi-func-test-file-host.sh && ./hack/build/build-cdi-func-test-registry-host.sh && ./hack/build/build-copy-artifacts.sh ${WHAT}"

build-controller: WHAT = cmd/cdi-controller
build-controller: build
build-importer: WHAT = cmd/cdi-importer
build-importer: build
build-apiserver: WHAT = cmd/cdi-apiserver
build-apiserver: build
build-uploadproxy: WHAT = cmd/cdi-uploadproxy
build-uploadproxy: build
build-uploadserver: WHAT = cmd/cdi-uploadserver
build-uploadserver: build
build-cloner: WHAT = cmd/cdi-cloner
build-cloner: build
build-operator: WHAT = cmd/cdi-operator
build-operator: build
build-functest-file-image-init: WHAT = tools/cdi-func-test-file-host-init
build-functest-file-image-init:
build-functest-registry-image-init: WHAT= tools/cdi-func-test-registry-init
build-functest-registry-image-init:
build-functest:
	${DO} ./hack/build/build-functest.sh

# WHAT must match go tool style package paths for test targets (e.g. ./path/to/my/package/...)
test: test-unit test-functional test-lint

test-unit: WHAT = ./pkg/... ./cmd/...
test-unit:
	${DO} "./hack/build/run-tests.sh ${WHAT}"

test-functional:  WHAT = ./tests/...
test-functional:
	./hack/build/run-functional-tests.sh ${WHAT} "${TEST_ARGS}"

test-functional-ci: build-functest test-functional

# test-lint runs gofmt and golint tests against src files
test-lint:
	${DO} "./hack/build/run-lint-checks.sh"

docker: build
	./hack/build/build-docker.sh build ${WHAT}

docker-controller: WHAT = cmd/cdi-controller
docker-controller: docker
docker-importer: WHAT = cmd/cdi-importer
docker-importer: docker
docker-cloner: WHAT = cmd/cdi-cloner
docker-cloner: docker
docker-apiserver: WHAT = cmd/cdi-apiserver
docker-apiserver: docker
docker-uploadproxy: WHAT = cmd/cdi-uploadproxy
docker-uploadproxy: docker
docker-uploadserver: WHAT = cmd/cdi-uploadserver
docker-uploadserver: docker
docker-operator: WHAT = cmd/cdi-operator
docker-operator: docker
docker-functest-images: docker-functest-image-http docker-functest-image-init docker-functest-registry-init docker-functest-registry-populate docker-functest-registry docker-functest-block-device
docker-functest-image-init: WHAT = tools/cdi-func-test-file-host-init
docker-functest-image-init: docker
docker-functest-image-http: WHAT = tools/cdi-func-test-file-host-http
docker-functest-image-http: # no code to compile, just build image
	./hack/build/build-cdi-func-test-file-host.sh && ./hack/build/build-docker.sh build ${WHAT}
docker-functest-registry-init: WHAT = tools/cdi-func-test-registry-init
docker-functest-registry-init: docker 
	./hack/build/build-cdi-func-test-file-host.sh && ./hack/build/build-docker.sh build ${WHAT}
docker-functest-registry-populate: WHAT = tools/cdi-func-test-registry-populate
docker-functest-registry-populate: # no code to compile, just build image
	./hack/build/build-cdi-func-test-registry-host.sh && ./hack/build/build-docker.sh build ${WHAT}
docker-functest-registry: WHAT = tools/cdi-func-test-registry
docker-functest-registry: # no code to compile, just build image
	./hack/build/build-cdi-func-test-registry-host.sh && ./hack/build/build-docker.sh build ${WHAT}

docker-registry-cleanup: 
	./hack/build/cleanup_docker.sh 


push: docker
	./hack/build/build-docker.sh push ${WHAT}

push-controller: WHAT = cmd/cdi-controller
push-controller: push
push-importer: WHAT = cmd/cdi-importer
push-importer: push
push-cloner: WHAT = cmd/cdi-cloner
push-cloner: push
push-apiserver: WHAT = cmd/cdi-apiserver
push-apiserver: push
push-uploadproxy: WHAT = cmd/cdi-uploadproxy
push-uploadproxy: push
push-uploadserver: WHAT = cmd/cdi-uploadserver
push-uploadserver: push
push-operator: WHAT = cmd/cdi-operator
push-operator: push

publish: manifests docker
	./hack/build/build-docker.sh publish ${WHAT}

vet:
	${DO} "./hack/build/build-go.sh vet ${WHAT}"

format:
	${DO} "./hack/build/format.sh"

manifests:
	${DO} "DOCKER_PREFIX=${DOCKER_PREFIX} DOCKER_TAG=${DOCKER_TAG} VERBOSITY=${VERBOSITY} PULL_POLICY=${PULL_POLICY} NAMESPACE=${NAMESPACE} ./hack/build/build-manifests.sh"

goveralls: test-unit
	${DO} "TRAVIS_JOB_ID=${TRAVIS_JOB_ID} TRAVIS_PULL_REQUEST=${TRAVIS_PULL_REQUEST} TRAVIS_BRANCH=${TRAVIS_BRANCH} ./hack/build/goveralls.sh"

release-description:
	./hack/build/release-description.sh ${RELREF} ${PREREF}

cluster-up:
	./cluster-up/up.sh

cluster-down: 
	./cluster-up/down.sh

cluster-down-purge: docker-registry-cleanup cluster-down

cluster-clean:
	./cluster-sync/clean.sh

cluster-sync: cluster-clean
	./cluster-sync/sync.sh DOCKER_PREFIX=${DOCKER_PREFIX} DOCKER_TAG=${DOCKER_TAG}

cluster-sync-controller: WHAT = cmd/cdi-controller
cluster-sync-controller: cluster-sync
cluster-sync-importer: WHAT = cmd/cdi-importer
cluster-sync-importer: cluster-sync
cluster-sync-cloner: WHAT = cmd/cdi-cloner
cluster-sync-cloner: cluster-sync
cluster-sync-apiserver: WHAT = cmd/cdi-apiserver
cluster-sync-apiserver: cluster-sync
cluster-sync-uploadproxy: WHAT = cmd/cdi-uploadproxy
cluster-sync-uploadproxy: cluster-sync
cluster-sync-uploadserver: WHAT = cmd/cdi-uploadserver
cluster-sync-uploadserver: cluster-sync

