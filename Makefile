# Copyright 2017 The kubecfg authors
#
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

VERSION ?= dev-$(shell date +%FT%T%z)

GO ?= go
GO_FLAGS ?=
GO_LDFLAGS ?=
GO_TESTFLAGS ?= -race
GO_BUILDFLAGS ?= -tags netgo -installsuffix netgo -ldflags="-X main.version=$(VERSION) $(GO_LDFLAGS)"
GOFMT ?= gofmt
# GINKGO = "go test" also works if you want to avoid ginkgo tool
GINKGO ?= ginkgo
GO_BINDATA ?= go-bindata

JSONNET_FILES = lib/kubecfg_test.jsonnet examples/guestbook.jsonnet
# TODO: Simplify this once ./... ignores ./vendor
GO_PACKAGES = ./cmd/... ./utils/... ./pkg/...

# Default cluster from this config is used for integration tests
KUBECONFIG ?= $(HOME)/.kube/config

all: kubecfg

kubecfg:
	CGO_ENABLED=0 $(GO) build $(GO_FLAGS) $(GO_BUILDFLAGS) .

generate:
	$(GO) generate -x $(GO_PACKAGES)

test: gotest jsonnettest

gotest:
	$(GO) test $(GO_FLAGS) $(GO_BUILDFLAGS) $(GO_TESTFLAGS) $(GO_PACKAGES)

jsonnettest: kubecfg $(JSONNET_FILES)
#	TODO: use `kubecfg validate` once it works offline
	./kubecfg show $(JSONNET_FILES) >/dev/null

integrationtest: kubecfg
	$(GINKGO) -tags 'integration' integration -- -kubeconfig $(KUBECONFIG) -kubecfg-bin $(abspath $<)

vet:
	$(GO) vet $(GO_FLAGS) $(GO_PACKAGES)

fmt:
	$(GOFMT) -s -w $(shell $(GO) list -f '{{.Dir}}' $(GO_PACKAGES))

clean:
	$(RM) ./kubecfg

.PHONY: all test clean vet fmt
.PHONY: kubecfg
