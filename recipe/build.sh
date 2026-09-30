#!/usr/bin/env bash

set -euxo pipefail

# Globs of libraries with CUDA device code to verify with check-cuda-arch. Outputs
# without device code leave this empty.
arch_libs=()

case "${PKG_NAME}" in
  libnvinfer-headers)
    tar --zstd -xf tensorrt.tar.zst --strip-components=1 --wildcards \
      '*/include/NvInfer*' \
      '*/include/NvOnnx*' \
      '*/doc/README.txt' \
      '*/doc/Acknowledgements.txt'
    rm -f tensorrt.tar.zst
    mkdir -p "${PREFIX}/include"
    mv -v include/NvInfer* include/NvOnnx* "${PREFIX}/include/"
    exit 0
    ;;
  libnvinfer-devel)
    files=('*/lib/libnvinfer.so')
    ;;
  tensorrt-tools)
    files=('*/bin/trtexec' '*/bin/tensorrt_player')
    arch_libs=('bin/trtexec')
    ;;
  libnvinfer-dispatch-devel)
    files=('*/lib/libnvinfer_dispatch.so')
    ;;
  libnvinfer-lean-devel)
    files=('*/lib/libnvinfer_lean.so')
    ;;
  libnvinfer-plugin-devel)
    files=('*/lib/libnvinfer_plugin.so')
    ;;
  libnvinfer-vc-plugin-devel)
    files=('*/lib/libnvinfer_vc_plugin.so')
    ;;
  libnvonnxparser-devel)
    files=('*/lib/libnvonnxparser.so')
    ;;
  libnvinfer)
    files=(
      '*/lib/libnvinfer.so.*'
      '*/lib/libnvinfer_builder_resource_ptx.so.*'
      '*/lib/libnvinfer_builder_resource_sm*.so.*'
    )
    # cuobjdump cannot see the device code embedded in the builder_resource libraries.
    arch_libs=('lib/libnvinfer.so.*')
    ;;
  libnvinfer-win-builder-resource)
    files=('*/lib/libnvinfer_builder_resource_win_*.so.*')
    ;;
  libnvinfer-dispatch)
    files=('*/lib/libnvinfer_dispatch.so.*')
    ;;
  libnvinfer-lean)
    files=('*/lib/libnvinfer_lean.so.*')
    arch_libs=('lib/libnvinfer_lean.so.*')
    ;;
  libnvinfer-plugin)
    files=('*/lib/libnvinfer_plugin.so.*')
    arch_libs=('lib/libnvinfer_plugin.so.*')
    ;;
  libnvinfer-vc-plugin)
    files=('*/lib/libnvinfer_vc_plugin.so.*')
    arch_libs=('lib/libnvinfer_vc_plugin.so.*')
    ;;
  libnvonnxparser)
    files=('*/lib/libnvonnxparser.so.*')
    ;;
  *)
    echo "Unknown TensorRT output: ${PKG_NAME}" >&2
    exit 1
    ;;
esac

tar --zstd -xf tensorrt.tar.zst --strip-components=1 --wildcards \
  "${files[@]}" \
  '*/doc/README.txt' \
  '*/doc/Acknowledgements.txt'
rm -f tensorrt.tar.zst

if (( ${#arch_libs[@]} > 0 )); then
  arch_files=()
  # Expand the globs here, after extraction, and skip symlinks to the same library.
  # shellcheck disable=SC2068
  for f in ${arch_libs[@]}; do
    [[ -L "${f}" ]] || arch_files+=("${f}")
  done
  check-cuda-arch "${arch_files[@]}"
fi

mkdir -p "${PREFIX}/lib"
if compgen -G 'lib/*.so.*' > /dev/null; then
  check-glibc lib/*.so.*
  mv -v lib/*.so.* "${PREFIX}/lib/"
fi
if compgen -G 'lib/*.so' > /dev/null; then
  mv -v lib/*.so "${PREFIX}/lib/"
fi
if [[ -d bin ]]; then
  mkdir -p "${PREFIX}/bin"
  check-glibc bin/*
  mv -v bin/* "${PREFIX}/bin/"
fi
