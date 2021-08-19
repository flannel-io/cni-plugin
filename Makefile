.PHONY: build_linux build_windows test_linux

build_linux:
	GOOS=linux scripts/build_flannel.sh

build_windows:
	GOOS=windows scripts/build_flannel.sh

test_linux:
	scripts/test_linux.sh
