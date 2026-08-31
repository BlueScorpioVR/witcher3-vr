# The Witcher 3 VR

Play The Witcher 3 Next-Gen in VR with configurable stereo rendering, a movable VR HUD, first-person gameplay, cinema modes, DLSS, DLAA and TAAU support, optional frame generation and native OptiScaler support.

Its DX12 and VR architecture was informed by
[REFramework](https://github.com/praydog/REFramework) and
[UEVR](https://github.com/praydog/UEVR) by praydog; neither project is bundled
as a runtime dependency.

> [!WARNING]
> This project is under active development. Features may be incomplete,
> unstable, or incompatible with some hardware and game configurations.

> [!IMPORTANT]
> Gameplay currently requires a mouse and keyboard or a gamepad. VR motion
> controllers are not supported and are not currently planned.

## Highlights

### Three ways to play

| Mode | What it offers | Anti-aliasing and upscaling |
| --- | --- | --- |
| AER + AFW | The fastest stereo option. Best when you need the highest frame rate. | TAAU, DLSS or DLAA |
| Stereo | Both eyes are rendered every frame. Better image consistency at a higher performance cost. | No AA, FXAA, TAAU, DLSS or DLAA |
| Mono | The lightest mode. It has no stereo depth, but can be useful on slower systems. | No AA, FXAA, TAAU, DLSS or DLAA |

Asymmetric projection is enabled by default. Press `F2` to switch temporarily to symmetric projection if needed. This toggle is intended for testing and may be removed in a future release.

### Frame Generation for VR

OFXR is a VR frame-generation system based on optical flow. It can improve smoothness when the game cannot reach the headset refresh rate on its own.

- It has been tested with VDXR and partially tested with SteamVR OpenXR.
- FidelityFX is faster and can provide around a 50% frame-rate increase, but usually produces more artifacts.
- NVIDIA Optical Flow is cleaner, but generally provides a smaller increase of around 25%.
- Results vary by GPU, scene, resolution and headset refresh rate.
- Some overlays, including xrFPS, may report half the perceived frame rate while OFXR is active.
- The game must be started through `Witcher3VRLauncher.exe` for OFXR to load.

### Native OptiScaler Support

OptiScaler can now be used directly with the mod. It relies on NVIDIA NGX, so disable DLSS Override before using it.

### Cinema Modes

Cinema mode supports `5:4`, `4:3`, `16:10` and `16:9` presentation formats.

### First-Person View

First-person mode is available for exploration, combat, horseback riding and sailing. Some animations and unusual camera situations can still look better in third person.

### VR HUD Editor

HUD elements can be positioned in VR and saved from inside the game. Separate presets can be kept for different play styles and presentation modes.

## Current Support

| Feature | Status |
| --- | --- |
| OpenXR | Supported |
| VDXR | Supported and recommended for Quest headsets |
| SteamVR OpenXR | Supported; Alternative Resize may be required for Presentation Size |
| Mouse and keyboard / gamepad | Supported |
| VR motion controllers | Not supported |
| AER + AFW | Supported |
| Stereo rendering | Supported |
| Mono rendering | Preliminary |
| No AA / FXAA / TAAU / DLSS / DLAA | Supported, depending on render mode |
| OptiScaler | Supported |
| OFXR frame generation | Experimental; tested with VDXR and partially with SteamVR OpenXR |

The most frequently tested configurations are Quest 3 through VDXR and Pimax headsets through SteamVR OpenXR. Other OpenXR runtimes may work but need more user feedback.

The ForceDLAA parameter-query and resolution-override approach is adapted from
[DLSSTweaks](https://github.com/emoose/DLSSTweaks) by emoose.

### Not Supported

- Ray tracing
- Screen Space Reflections (High)
- Far/Distant game camera modes for exploration, combat and horse riding; only close/near cameras are currently corrected

## Requirements

- The Witcher 3 Next-Gen, DirectX 12 version
- A working OpenXR runtime for your headset
- A mouse and keyboard or gamepad
- Windows 10 or Windows 11
- A VR-ready GPU and CPU
- The current Microsoft Visual C++ Redistributable

DLSS and DLAA require a compatible NVIDIA GPU. OptiScaler and OFXR have their own hardware and software requirements.

## Installation

1. Extract the release archive into the Witcher 3 game folder, the directory containing `bin`, `content` and `mods`.
2. Allow the folders from the archive to merge with the existing game folders.
3. Run `bin\x64_dx12\Witcher3VRLauncher.exe`.
4. Choose your settings, then select **Save & Launch**.

The complete release includes the VR DLL, launcher, configuration, scripts and bundled mod files inside the correct `bin\x64_dx12`, `mods`, `dlc` and `Witcher3VR` folders. Install the whole package when changing release versions; replacing only the DLL can leave incompatible files behind.

Back up any files you have edited manually before installing a new release.

## Launcher Guide

### First-Time Setup

Press **Configure Settings for VR** at least once before playing. It applies the tested game profile and creates a backup that can be restored later with **Restore Original Settings**.

### Resolution

`AUTO` follows the headset and runtime configuration. Use a fixed resolution when you want predictable image quality or need to reduce GPU load.

Lower resolutions improve performance but reduce clarity. Very high resolutions can become GPU-limited even when the game itself appears to have spare performance.

### Presentation Size

`1.00` uses the full presentation area. Lower values zoom the view out and add unused space around it. On Quest 3, `0.85` is a useful starting point for increasing visible pixel density without normally seeing the black borders.

Enable **Alt. Resize** only if changing Presentation Size does not work correctly with your OpenXR bridge. It is required for this feature on SteamVR in the configurations tested so far, but can slightly reduce image quality. Leave it disabled when normal resize already works.

### World Detail Range

The default value is `100%`, preserving the normal extended world-detail range.

Lowering it can recover performance in cities and other CPU-heavy areas by reducing how far detailed objects remain visible. At `40%`, the extended LOD/culling correction is effectively disabled. Use the highest value that gives stable performance on your headset.

### Asymmetric Projection

Asymmetric projection is enabled by default and provides the intended image and performance path. Press `F2` in game for a temporary switch to symmetric projection when diagnosing a visual problem.

### OFXR Frame Generation

- **FidelityFX:** higher performance, more visible artifacts.
- **NVIDIA:** lower performance gain, fewer artifacts.
- **Off:** native game frames only.

Start the game from the VR Launcher whenever OFXR is enabled.

### OptiScaler

Disable DLSS Override before enabling OptiScaler.

### Cinema

Choose `5:4`, `4:3`, `16:10` or `16:9` according to the content and the amount of peripheral view you want.

### Diagnostic Logging

Enable **Diagnostic Logging** only while collecting detailed information for a bug report. It is heavy and can affect timing or performance measurements.

**Route Log** is lightweight and can remain enabled without affecting performance. It records recent TAAU, DLSS and AFW routing events in memory and writes them only when you press `F3`.

## Recommended Game Settings

These are starting points rather than strict requirements:

| Setting | Recommendation |
| --- | --- |
| DirectX | DX12 |
| Ray tracing | Off |
| Screen-space reflections | Off or Low |
| NVIDIA Reflex | Off |
| Motion blur | Off |
| Blur | Off |
| Bloom | Off if it causes discomfort or visual artifacts |
| Lens effects | Off if they look detached in VR |
| Shadows | High or lower when CPU-limited |
| HairWorks | Off |
| VSync | Off |
| Frame-rate limit | Off, or set to suit the headset and frame-generation mode |

### Texture Quality and LOD

The Texture Quality setting also affects LOD behaviour. Higher values keep detailed geometry and textures visible farther away, but may increase distant shimmering.

Suggested values:

- **No AA / FXAA:** Medium
- **TAAU / DLSS:** Medium or High
- **DLAA:** Higher values may be practical if performance allows

## Useful Shortcuts

| Key | Action |
| --- | --- |
| `F2` | Toggle asymmetric/symmetric projection temporarily |
| `F3` | Write the recent Route Log and Performance Log events |
| `F7` | Switch between the VR and Cinema3D HUD layouts |
| `F8` | Toggle Standard and Near views |
| `F9` | Recenter the VR view |
| `F10` | Toggle Cinema Mode |
| `F11` | Toggle First Person |

Shortcuts may conflict with overlays or other mods. Disable or rebind conflicting software when a key does not respond.

## HUD Editor

| Control | Action |
| --- | --- |
| `Insert` | Open the editor, or save and close it |
| `Q` / `E` | Select the previous or next panel |
| Arrow keys | Move the selected panel |
| Mouse wheel | Resize the selected panel |
| `R` | Reset the selected panel |
| `X` | Reset the active HUD layout |
| `F7` | Switch between the VR and Cinema3D HUD layouts |

The editor can separately position gameplay and cutscene subtitles, dialogue text and choices. Keep separate backups of layouts you want to reuse after reinstalling the mod.

## Known Issues

- OFXR has been tested with VDXR and partially with SteamVR OpenXR. Other runtimes need validation.
- Some FPS overlays report half frame rate while OFXR is active.
- Mono mode is preliminary. Some cutscenes may not retain DLSS/DLAA or TAAU.
- Ray tracing is temporarily unsupported because it does not currently work correctly with asymmetric projection.
- Screen-space reflections on High can produce distracting stereo artifacts.
- Motion blur, bloom and lens effects can look uncomfortable or detached in VR.
- Some terrain can still look incorrect in a few Full VR cutscenes.
- First-person mode can expose animation and camera issues, especially while moving backward or during scripted sequences.
- Very distant cameras and some cutscenes may still show visual inconsistencies.

You are free to use other mods, but third-party mod compatibility is not
supported during this stage of development. Before reporting a Witcher 3 VR
bug, disable all other mods and reproduce the problem on an otherwise supported
installation. Please do not open issues for problems that occur only while
another mod is installed. This is a temporary development-scope limitation, not
a restriction on using mods.

## Troubleshooting

### The game does not enter VR

- Confirm that the correct OpenXR runtime is active.
- Turn off Windows HDR.
- Close RivaTuner Statistics Server (RTSS), including any overlay using it.
- Start the game through `bin\x64_dx12\Witcher3VRLauncher.exe`.
- Temporarily disable overlays and other DLL injectors.
- Reinstall the complete release package instead of replacing only the DLL.

### The image is distorted after changing Presentation Size

- Restore Presentation Size to `1.00`.
- If you use SteamVR OpenXR, enable **Alt. Resize** and test again.
- If resize already works normally, keep **Alt. Resize** disabled for the best image quality.

### Performance is poor in cities

The Witcher 3 is already CPU-bound in busy cities, and the VR mod increases CPU load further. A recent high-end CPU is required for consistently high frame rates in these areas.

- Lower World Detail Range gradually.
- Reduce shadows, crowd density and background characters.
- Try AER + AFW instead of full stereo.
- Reduce render resolution before reducing texture quality.
- Test OFXR with VDXR if native performance is still insufficient.

### OptiScaler does not work

- Disable DLSS Override.

## Bug Reports

When reporting a problem, include:

- Headset and OpenXR runtime
- GPU and driver version
- Render mode and anti-aliasing/upscaler mode
- Resolution, Presentation Size, Alt. Resize and World Detail Range settings
- Whether OFXR or OptiScaler is active
- A short description of where the issue occurs
- A diagnostic log only when requested or when it clearly captures the problem

## Support

The mod is free and publicly available. Donations are entirely optional and
never provide exclusive builds, features, or support.

If you would like to support development, you can do so through
[Ko-fi](https://ko-fi.com/tig3rmast3r) or by using the Sponsor button at the
top of the repository.

## Credits

- [praydog / REFramework](https://github.com/praydog/REFramework) — DX12
  hooking and VR architecture reference
- [praydog / UEVR](https://github.com/praydog/UEVR) — additional VR
  implementation reference
- [emoose / DLSSTweaks](https://github.com/emoose/DLSSTweaks) — ForceDLAA
  parameter-query and resolution-override approach
- [Next Gen Movement Input Lag Fix — Fumio Edition](https://www.nexusmods.com/witcher3/mods/7586)
  — behavior-graph foundation for the optional Fast Transitions DLC
- [MinHook](https://github.com/TsudaKageyu/minhook) — Windows API hooking
  library
- [Khronos OpenXR SDK](https://github.com/KhronosGroup/OpenXR-SDK)
- [Microsoft DirectX-Headers](https://github.com/microsoft/DirectX-Headers)
- [NVIDIA NGX SDK](https://github.com/NVIDIA-RTX/Streamline/blob/main/external/ngx-sdk/license.txt)
- The authors of the bundled movement and frame-generation components
- Testers who provided headset-specific feedback, logs and performance comparisons

See [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) for copyright notices and
third-party licensing information.

## Contributing

Development information is available in [CONTRIBUTING.md](CONTRIBUTING.md). The README intentionally focuses on installing, configuring and playing the mod.

## License

Original Witcher 3 VR code is released under the [MIT License](LICENSE), unless
otherwise stated.

Third-party software remains the property of its respective authors and is
distributed under its own license terms. The project's MIT license does not
relicense third-party components or NVIDIA SDK materials.

## Disclaimer

> This is an unofficial fan work and is not approved or endorsed by
> CD PROJEKT RED.

This project is not affiliated with CD PROJEKT RED, CD PROJEKT S.A., NVIDIA, or
the authors of the third-party projects listed above.

All trademarks, game content, and related intellectual property belong to
their respective owners. This project does not distribute game assets and
requires a legally obtained copy of *The Witcher 3: Wild Hunt*.

The software is provided as-is and without warranty. Use it at your own risk
and keep backups of saves and configuration files.

This project is intended to comply with the
[CD PROJEKT RED Fan Content Guidelines](https://www.cdprojektred.com/en/fan-content).
