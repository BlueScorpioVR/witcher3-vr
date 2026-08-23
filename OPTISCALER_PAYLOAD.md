# V1410 OptiScaler payload

V1410 uses the official OptiScaler v0.9.4 stable archive:

- Release: https://github.com/optiscaler/OptiScaler/releases/tag/v0.9.4
- Archive: `Optiscaler_0.9.4-final.20260718._MM.7z`
- Archive SHA-256:
  `575CB4DF866116093DF75AF607E37FD70E10F5163E0F23FD5C804142E80EF0AD`

Only the upscaler payload is required beside `witcher3.exe`:

- `OptiScaler.dll`, 25,379,632 bytes, SHA-256
  `FBFB6676B829DAD7E020FB830586A16AA0EC6ADD78016DB48EF12E2AE1803231`
- `amd_fidelityfx_dx12.dll`, 26,376 bytes, SHA-256
  `E2D85AA05A9BD9ED8B38935FDF5199372CCA6F74C12015143BB6F945EE1608AA`
- `amd_fidelityfx_upscaler_dx12.dll`, 28,761,864 bytes, SHA-256
  `D0DCCCC74A43C44BA435B7A369B456E0970D8A4464E4BD683119B374F2C9FB46`
- `OptiScaler.ini`, configured as below, 47,474 bytes, SHA-256
  `26BD9010A33DBD42370026FB04B9D675B704EB889682C79354D9210876A61A82`
- this build's `optiscaler_bridge.ini`.

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
