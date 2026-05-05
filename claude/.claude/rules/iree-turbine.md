---
globs: "**/iree-turbine/**"
description: IREE-Turbine ML frontend — BOO driver, convolution testing, ROCm setup
---

## IREE-Turbine Integration

IREE-Turbine is a Python-based ML frontend that uses IREE as its backend compiler.

### Build Integration
When compiling IREE under `build/model`, iree-turbine will automatically pick up the changes.

### Key Locations
- Turbine driver: `~/iree-turbine/iree/turbine/kernel/boo/driver/driver.py`
- BOO (Backend Optimization Operations) driver for convolution testing

### Running Convolution Tests
```bash
cd ~/iree-turbine/iree/turbine/kernel/boo/driver
python driver.py convbfp16 -n 1 -c 896 -H 59 -W 91 -k 896 -y 3 -x 3 \
  -p 1 -q 1 -u 1 -v 1 -l 1 -j 1 \
  --in_layout NHWC --fil_layout NHWC --out_layout NHWC \
  -m conv -g 16 -F 1 -t 1
```

## GPU/ROCm Setup

### Device Access
If GPU tests fail with "no ROCm-capable device" despite `rocminfo` showing devices:
1. Check device permissions: `/dev/kfd` and `/dev/dri/renderD*` need `render` group access
2. Quick fix: `chmod 666 /dev/kfd /dev/dri/renderD*`
