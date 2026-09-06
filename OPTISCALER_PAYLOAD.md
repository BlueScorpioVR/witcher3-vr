# OptiScaler references for 0.9.7

The ordinary reference uses the official OptiScaler v0.9.4 stable archive:

- Release: https://github.com/optiscaler/OptiScaler/releases/tag/v0.9.4
- Archive: `Optiscaler_0.9.4-final.20260718._MM.7z`
- Archive SHA-256:
  `575CB4DF866116093DF75AF607E37FD70E10F5163E0F23FD5C804142E80EF0AD`

The launcher copies the following from `witcher3vr-optiscaler-reference` beside `witcher3.exe`:

- `OptiScaler.dll`, 25,379,632 bytes, SHA-256
  `FBFB6676B829DAD7E020FB830586A16AA0EC6ADD78016DB48EF12E2AE1803231`
- `OptiScaler.ini`, configured as below, with Delete as the menu key and 75% UI scale.
- this build's `optiscaler_bridge.ini`.

The ordinary integration uses the FidelityFX DLLs already supplied with The Witcher 3. It
does not redistribute or replace them.

Required `OptiScaler.ini` overrides from the release default:

```ini
[Upscalers]
Dx12Upscaler=fsr31

[FrameGen]
Enabled=false

[DLSS]
Enabled=false

[Spoofing]
StreamlineSpoofing=true

[Log]
LogToFile=false
```

Keep the exact filename `OptiScaler.dll`; do not rename it to `dxgi.dll`,
`winmm.dll`, or another proxy name. It is dormant while
`optiscaler_bridge.ini` has `enabled=0`. V1410 and later builds explicitly load
this exact adjacent module only with `enabled=1`, then route private NGX
Create/Evaluate/Release through it.

The DLSS5 mode instead copies the stereo-aware fork DLL, its INI and
`nvngx.dll_dlssnr.dll` from `witcher3vr-optiscaler-dlss5-reference`.
This is the VR v2 pre-DLSS build from tag `v0.1.1-dlssnr-vr2`:

- `OptiScaler.dll`, 25,735,680 bytes, SHA-256
  `1876A8E06A4B280B41380FBB6D3F3EFEE5699175FD631C3D7D95102E572380A6`
- `OptiScaler.ini`, configured for the Witcher 3 DLSS route, Delete menu key,
  100% pre-DLSS working scale and bounded capture off; 55,669 bytes, SHA-256
  `7EB791934CDC2E499DD8D458DC6F5F2CF48F5B74EDC771F5B13611CC6938E557`
- `nvngx.dll_dlssnr.dll`, 109,056 bytes, SHA-256
  `BE90DBC0AA368AC1845B99A9AE5129C329F85970E83F885D4BE6E2F128FBE4E0`

That last file is the custom NGX forwarder, not NVIDIA's DLSS5 runtime.
Only user-supplied `nvngx_dlss.dll`, `nvngx_dlssg.dll` and `nvngx_dlssnr.dll`
belong in `witcher3vr-dlss5-reference`; distribution leaves that folder empty.
The launcher reads all reference folders without changing them.
