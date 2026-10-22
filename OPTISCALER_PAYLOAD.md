# OptiScaler payload for Witcher 3 VR 0.9.8

There is one custom OptiScaler: **V23244**, based on the pre-Wilsjo public fork.
Its rendering matches V23238; gameplay logging is disabled by default.

`bin/x64_dx12/witcher3vr-optiscaler-dlss5-reference` contains:

- `OptiScaler.dll` (V23244).
- `nvngx.dll_dlssnr.dll`, our NGX forwarding helper, not NVIDIA's NR runtime.
- The two private FidelityFX frame-generation helpers required by this integration.

The single `OptiScaler.ini` lives in `bin/x64_dx12`. Existing user settings are
preserved by the launcher. Open the OptiScaler GUI with Delete.

Only if using DLSS 5 Neural Rendering, supply `nvngx_dlssnr.dll` separately in
`bin/x64_dx12/witcher3vr-dlss5-reference`. That folder is empty in the ZIP.
Neither `nvngx_dlss.dll` nor `nvngx_dlssg.dll` is required in that reference.
No proprietary NVIDIA DLSS runtime is bundled.

FSR 3.1 and Nvidia (new) require OptiScaler. FSR also requires the game to use
DLSS/DLAA. FidelityFX and legacy Nvidia remain available without OptiScaler
through the separate OFXR v0.2.1 layer. With OptiScaler selected, that layer
bootstraps the embedded implementation and its OFXR VR Framegen GUI.

The ordinary OptiScaler and managed ReShade DLSS5 add-on routes are absent.
Plain ReShade is included; optional add-ons are user-installed and unsupported.

Source: https://github.com/tig3rmast3r/OptiScaler_DLSSNR_VR/tree/v23244
License: GPL-3.0; component notices and licenses accompany the release.
