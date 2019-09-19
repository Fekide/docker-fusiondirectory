all: build

build:
	@docker build -t fekide/fusiondirectory:latest .

release: build
	@docker build -t fekide/fusiondirectory:$(shell cat Dockerfile | \
		grep version | \
		sed -e 's/[^"]*"\([^"]*\)".*/\1/') .

.PHONY: test
test:
	@docker build -t fekide/fusiondirectory:bats .
	bats test
