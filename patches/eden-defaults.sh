#!/bin/bash
# Bake S25 Ultra (Snapdragon 8 Elite / Adreno 830) COMPATIBILITY-FIRST defaults
# into Eden source. Philosophy: deviate from stock defaults only where the
# change cannot break a game, or where it strictly improves correctness.
# Applied on top of a fresh clone before every CI build. Anchors are matched
# literally; a missing anchor emits a warning instead of failing the build so
# upstream refactors degrade gracefully.
SRC="${1:-eden}"
H="$SRC/src/common/settings.h"

apply() { # apply <description> <from> <to>
  if grep -qF "$2" "$H"; then
    sed -i "s|$2|$3|" "$H"
    echo "patched: $1"
  else
    echo "::warning::anchor missing, skipped: $1"
  fi
}

# Zero compatibility risk (post-process / clocks / filtering only):
apply "window filter -> FSR"        "ScalingFilter::Bilinear,"                "ScalingFilter::Fsr,"
apply "force max GPU clocks -> on"  "renderer_force_max_clock{linkage, false" "renderer_force_max_clock{linkage, true"
apply "anisotropy -> automatic"     "AnisotropyMode::Default,"                "AnisotropyMode::Automatic,"

# Compatibility IMPROVEMENT: higher GPU emulation accuracy (desktop default),
# fixes shader math / vertex issues at some performance cost:
apply "gpu accuracy -> High"        "GpuAccuracy::Low,"                       "GpuAccuracy::High,"

# Intentionally NOT patched (kept at stock defaults for maximum compatibility):
#   resolution_setup Res1X, use_docked_mode Handheld, use_asynchronous_shaders
#   false, vram_usage_mode Conservative, memory_layout_mode Memory_4Gb.

echo "--- resulting defaults ---"
grep -n "ScalingFilter::Fsr,\|renderer_force_max_clock{linkage, true\|AnisotropyMode::Automatic,\|GpuAccuracy::High," "$H" || true
