#   Copyright 2020 Docker Hub Tool authors

#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at

#       http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
include vars.mk
export DOCKER_BUILDKIT=1

DOCKER_BUILD:=docker buildx build

BUILD_ARGS:=--build-arg GO_VERSION=$(GO_VERSION) \
    --build-arg CLI_VERSION=$(CLI_VERSION) \
    --build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
    --build-arg GOLANGCI_LINT_VERSION=$(GOLANGCI_LINT_VERSION) \
    --build-arg TAG_NAME=$(TAG_NAME) \
    --build-arg GOTESTSUM_VERSION=$(GOTESTSUM_VERSION) \
    --build-arg BINARY_NAME=$(BINARY_NAME) \
    --build-arg BINARY=$(BINARY)

.PHONY: mod-tidy
mod-tidy: ## Update go.mod and go.sum
	$(DOCKER_BUILD) $(BUILD_ARGS) . \
		--output type=local,dest=. \
		--platform local \
		--target go-mod-tidy

.PHONY: test ## Run unit tests then end-to-end tests
test: test-unit e2e

.PHONY: e2e-build
e2e-build:
	$(DOCKER_BUILD) $(BUILD_ARGS) . --target e2e -t $(BINARY_NAME):e2e

.PHONY: e2e
e2e: e2e-build ## Run the end-to-end tests
	docker run $(E2E_ENV) --rm \
		-v /var/run/docker.sock:/var/run/docker.sock \
		-v $(shell go env GOCACHE):/root/.cache/go-build \
		-v $(shell go env GOMODCACHE):/go/pkg/mod \
		$(BINARY_NAME):e2e

.PHONY: test-unit-build
test-unit-build:
	$(DOCKER_BUILD) $(BUILD_ARGS) . --target test-unit -t $(BINARY_NAME):test-unit

.PHONY: test-unit
test-unit: test-unit-build ## Run unit tests
	docker run --rm \
		-v $(shell go env GOCACHE):/root/.cache/go-build \
		-v $(shell go env GOMODCACHE):/go/pkg/mod \
		$(BINARY_NAME):test-unit

.PHONY: lint
lint: ## Run the go linter
	@$(DOCKER_BUILD) $(BUILD_ARGS) . --target lint

.PHONY: help
help: ## Show help
	@echo Please specify a build target. The choices are:
	@grep -E '^[0-9a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":| ## "}; {printf "\033[36m%-30s\033[0m %s\n", $$2, $$NF}'
