# The Witcher 3 VR 0.9.7

> [!WARNING]
> Intermittent crashes, hangs and black-screen starts may occur when using
> ReShade.
> This development release includes fixes, but does not resolve every case.

> [!IMPORTANT]
> Alpha 2 includes the new OptiScaler VR v2 for DLSS. It is more stable, moves neural
> rendering before DLSS and runs 50% faster than ReShade. We strongly recommend
> using OptiScaler for DLSS.

## New features

- **ReShade support.**
- **ReShade DLSS5 support through RenoDX.**
- **OptiScaler DLSS5 support**, using our stereo-compatible fork.

All integrations are selectable from the launcher. The default is **Off**.

## Fixes and improvements

- **Fixed the reproduced ReShade / SteamVR startup crash.** The package uses [our unofficial ReShade VR fork](https://github.com/tig3rmast3r/ReShade_VR), based on 6.8.0, with a targeted DirectX 11/12 compatibility fix validated in Witcher3VR.
- **Presentation Size now improves perceived clarity instead of cropping the image.** Lowering the slider preserves the full image and presents the same rendered pixel resolution in a smaller area, increasing visible pixel density without raising the render resolution. At `1.00`, the normal presentation is unchanged.
- **Alt resize is no longer needed and has been removed.** The standard slider works with both VDXR and SteamVR.
- **Updated OFXR.** The NVIDIA option now uses the medium preset with 50% optical-flow input resolution; final output stays full resolution.
- **OFXR settings are preserved.** The launcher changes only the backend in the game's `ofxr_bridge.ini`; manually enabled OFXR logging stays enabled across launches. OFXR logging is off by default and is independent of the mod's Diagnostic Logging checkbox.
- **HUD and AER integration fixes.** Improved HUD ownership tracking and command-list handling with ReShade. Intermittent startup failures are still known issues.

## How to use it

**Everything needed for the integrations is already in the package EXCEPT the NVIDIA DLSS5 DLLs.** ReShade, the RenoDX add-on, OptiScaler, OFXR and the launcher are already included. No separate ReShade installation or integration add-on package is needed.

1. Extract the archive into **The Witcher 3** game folder, merge the folders and overwrite the package files when prompted.
2. **Only if you want to use DLSS5:** download the DLSS5 files separately from another source, choosing the package for your GPU (**RTX 50xx or RTX 40xx**). Copy only these three files into `The Witcher 3\bin\x64_dx12\witcher3vr-dlss5-reference`:

   - `nvngx_dlss.dll`
   - `nvngx_dlssg.dll`
   - `nvngx_dlssnr.dll`

   This reference folder is empty in the release. Do not copy the rest of the downloaded package into it.
3. Open `Witcher3VRLauncher.exe` in `bin\x64_dx12`, choose your desired integration from the dropdown and click **Save & Launch**. For DLSS5, also select a DLSS/DLAA rendering mode. The launcher handles the required file copies and selects the correct add-on automatically.

You do not need the separate DLSS5 files for ordinary ReShade or OptiScaler. To disable the integrations, select **Off** and save.

## Credits

Thanks to [crosire / ReShade](https://github.com/crosire/reshade),
[clshortfuse and the RenoDX contributors](https://github.com/clshortfuse/renodx),
the [DLSS5 Neural Rendering add-on authors](https://discord.com/invite/renodx),
the [OptiScaler team](https://github.com/optiscaler/OptiScaler), and
[Dagherbou / OptiScaler_DLSSNR](https://github.com/Dagherbou/OptiScaler_DLSSNR).
Our compatibility changes are available in the
[ReShade VR fork](https://github.com/tig3rmast3r/ReShade_VR),
[OptiScaler VR fork](https://github.com/tig3rmast3r/OptiScaler_DLSSNR_VR).
Full component credits are in the README.

Internal build: **V1535**, consolidating the Special Edition integrations and
subsequent fixes into one release after the standard 0.9.6.
