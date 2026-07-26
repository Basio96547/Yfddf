#!/bin/bash
# Bake S25 Ultra (Snapdragon 8 Elite / Adreno 830) optimized defaults into Eden source.
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

apply "window filter -> FSR"          "ScalingFilter::Bilinear,"                  "ScalingFilter::Fsr,"
apply "resolution -> 2x"              "ResolutionSetup::Res1X,"                   "ResolutionSetup::Res2X,"
apply "force max GPU clocks -> on"    "renderer_force_max_clock{linkage, false"   "renderer_force_max_clock{linkage, true"
apply "async shader compile -> on"    "use_asynchronous_shaders{linkage, false"   "use_asynchronous_shaders{linkage, true"
apply "VRAM cache -> aggressive"      "VramUsageMode::Conservative,"              "VramUsageMode::Aggressive,"
apply "console mode -> docked"        "ConsoleMode::Handheld,"                    "ConsoleMode::Docked,"
apply "anisotropy -> automatic"       "AnisotropyMode::Default,"                  "AnisotropyMode::Automatic,"

# Emulated console RAM: 4GB -> 8GB devkit layout. The enum name lives in
# settings_enums.h, so resolve it from the real source at build time and
# skip safely if upstream renames it.
ENUMS="$SRC/src/common/settings_enums.h"
MEM8=$(grep -oE "Memory_8[A-Za-z0-9]*b" "$ENUMS" 2>/dev/null | head -1)
if [ -n "$MEM8" ]; then
  apply "emulated RAM -> 8GB ($MEM8)" "MemoryLayout::Memory_4Gb," "MemoryLayout::$MEM8,"
else
  echo "::warning::8GB memory layout enum not found in settings_enums.h, skipped"
fi

echo "--- resulting defaults ---"
grep -n "ScalingFilter::Fsr,\|ResolutionSetup::Res2X,\|renderer_force_max_clock{linkage, true\|use_asynchronous_shaders{linkage, true\|VramUsageMode::Aggressive,\|ConsoleMode::Docked,\|AnisotropyMode::Automatic," "$H" || true
