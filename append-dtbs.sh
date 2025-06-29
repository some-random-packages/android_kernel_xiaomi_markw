#!/bin/sh

cat arch/arm64/boot/Image.gz arch/arm64/boot/dts/qcom/*.dtb > arch/arm64/boot/Image.gz-dtb
