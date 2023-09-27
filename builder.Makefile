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

NULL:=/dev/null

ifeq ($(COMMIT),)
    COMMIT:=$(shell git rev-parse HEAD 2> $(NULL))
endif
ifeq ($(TAG_NAME),)
    TAG_NAME:=$(shell git describe --tags --match "v[0-9]*" 2> $(NULL))
endif

PKG_NAME:=github.com/martinalbert/hub-tool
STATIC_FLAGS:=CGO_ENABLED=0
LDFLAGS:="-s -w \
    -X $(PKG_NAME)/internal.GitCommit=$(COMMIT) \
    -X $(PKG_NAME)/internal.Version=$(TAG_NAME)"
GO_BUILD:=go build -trimpath -ldflags=$(LDFLAGS)
VARS:=BINARY_NAME=${BINARY_NAME} \
    BINARY=${BINARY}

ifneq ($(strip $(E2E_TEST_NAME)),)
    RUN_TEST=-test.run $(E2E_TEST_NAME)
endif

TAR_TRANSFORM:=--transform s/packaging/${BINARY_NAME}/ --transform s/bin/${BINARY_NAME}/ --transform s/${PLATFORM_BINARY}/${BINARY_NAME}/
ifneq ($(findstring bsd,$(shell tar --version)),)
    TAR_TRANSFORM=-s /packaging/${BINARY_NAME}/ -s /bin/${BINARY_NAME}/ -s /${PLATFORM_BINARY}/${BINARY_NAME}/
endif
TMPDIR_WIN_PKG:=$(shell mktemp -d)

.PHONY: lint
lint:
	$(STATIC_FLAGS) golangci-lint run --timeout 10m0s ./...

.PHONY: test-unit
test-unit:
	$(STATIC_FLAGS) gotestsum $(shell go list ./... | grep -vE '/e2e')

