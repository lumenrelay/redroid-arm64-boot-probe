#!/usr/bin/env bash
# Start the pinned redroid image with the fixed probe parameters.
set -euxo pipefail
IMG="$1"
sudo docker run -d \
  --name redroid-probe \
  --platform linux/arm64 \
  --privileged \
  --pull never \
  --restart no \
  --log-opt max-size=10m \
  --log-opt max-file=3 \
  --publish 127.0.0.1:5555:5555 \
  --mount type=bind,source=/srv/redroid-probe/data,target=/data \
  "$IMG" \
  androidboot.use_memfd=1 \
  androidboot.redroid_gpu_mode=guest \
  androidboot.redroid_width=720 \
  androidboot.redroid_height=1280 \
  androidboot.redroid_fps=15
sudo docker port redroid-probe
