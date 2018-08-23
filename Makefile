dist_files=ctanbib
package_name=ctanbib
build_dir=build
# Installation directory for the files
package_dist=${build_dir}/${package_name}
dist_package=${package_name}.zip

.PHONY: build
build:
	rm -rf ${build_dir} 
	mkdir -p ${package_dist}
	cp ${dist_files} ${package_dist}
	cd ${build_dir} && zip -r ${dist_package} ${package_name}
