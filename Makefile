package_name=ctanbib
build_dir=build
# Installation directory for the files
package_dist=${build_dir}/${package_name}
dist_package=${package_name}.zip
documentation_pdf=${package_name}-doc.pdf
documentation_src=${package_name}-doc.tex
dist_files=ctanbib ${documentation_pdf} README.md

ifeq ($(strip $(shell git rev-parse --is-inside-work-tree 2>/dev/null)),true)
	VERSION:= $(shell git --no-pager describe --abbrev=0 --tags --always )
	DATE:= $(firstword $(shell git --no-pager show --date=short --format="%ad" --name-only))
endif

.PHONY: build

all: ${documentation_pdf}

${documentation_pdf}: ${documentation_src} Makefile
	lualatex  "\def\gitversion{${VERSION}}\def\gitdate{${DATE}}\input{$<}"

build: ${documentation_pdf}
	rm -rf ${build_dir} 
	mkdir -p ${package_dist}
	cp ${dist_files} ${package_dist}
	sed -e "s/{{version}}/${VERSION}/" ${package_name} >  ${package_dist}/${package_name}
	cd ${build_dir} && zip -r ${dist_package} ${package_name}
