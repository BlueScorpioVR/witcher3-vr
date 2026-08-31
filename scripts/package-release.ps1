[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[Vv][0-9]+$')]
    [string] $Version,

    [string] $OutputDirectory = (Join-Path (Split-Path -Parent $PSScriptRoot) 'dist'),

    [string] $PureDarkPlugin,

    [string] $OfxrLayer,

    [string] $OptiScalerDll,

    [string] $OptiScalerIni,

    [string] $AmdFidelityFxDll,

    [string] $AmdFidelityFxUpscalerDll,

    [ValidatePattern('^[A-Za-z0-9._-]+$')]
    [string] $ArtifactName
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
$repositoryPrefix = $repositoryRoot.TrimEnd('\') + '\'
if (-not $resolvedOutput.StartsWith(
        $repositoryPrefix,
        [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputDirectory must be inside the repository workspace.'
}
$OutputDirectory = $resolvedOutput
$normalizedVersion = $Version.ToUpperInvariant()
$pureDarkPluginDefault = Join-Path $repositoryRoot `
    'external/puredark-afw/PDAFWPlugin.dll'
if ([string]::IsNullOrWhiteSpace($PureDarkPlugin)) {
    $PureDarkPlugin = $pureDarkPluginDefault
} else {
    $PureDarkPlugin = [System.IO.Path]::GetFullPath($PureDarkPlugin)
}
$ofxrLayerDefault = Join-Path $repositoryRoot `
    'external/ofxr/XR_APILAYER_XRFrameBridge_diagnostic.dll'
if ([string]::IsNullOrWhiteSpace($OfxrLayer)) {
    $OfxrLayer = $ofxrLayerDefault
} else {
    $OfxrLayer = [System.IO.Path]::GetFullPath($OfxrLayer)
}
$optiscalerDllDefault = Join-Path $repositoryRoot `
    'external/optiscaler/OptiScaler.dll'
if ([string]::IsNullOrWhiteSpace($OptiScalerDll)) {
    $OptiScalerDll = $optiscalerDllDefault
} else {
    $OptiScalerDll = [System.IO.Path]::GetFullPath($OptiScalerDll)
}
$optiscalerIniDefault = Join-Path $repositoryRoot `
    'external/optiscaler/OptiScaler.ini'
if ([string]::IsNullOrWhiteSpace($OptiScalerIni)) {
    $OptiScalerIni = $optiscalerIniDefault
} else {
    $OptiScalerIni = [System.IO.Path]::GetFullPath($OptiScalerIni)
}
$amdFidelityFxDllDefault = Join-Path $repositoryRoot `
    'external/optiscaler/amd_fidelityfx_dx12.dll'
if ([string]::IsNullOrWhiteSpace($AmdFidelityFxDll)) {
    $AmdFidelityFxDll = $amdFidelityFxDllDefault
} else {
    $AmdFidelityFxDll = [System.IO.Path]::GetFullPath($AmdFidelityFxDll)
}
$amdFidelityFxUpscalerDllDefault = Join-Path $repositoryRoot `
    'external/optiscaler/amd_fidelityfx_upscaler_dx12.dll'
if ([string]::IsNullOrWhiteSpace($AmdFidelityFxUpscalerDll)) {
    $AmdFidelityFxUpscalerDll = $amdFidelityFxUpscalerDllDefault
} else {
    $AmdFidelityFxUpscalerDll =
        [System.IO.Path]::GetFullPath($AmdFidelityFxUpscalerDll)
}
if ([string]::IsNullOrWhiteSpace($ArtifactName)) {
    $ArtifactName = "Witcher3VR-$normalizedVersion"
}
$pureDarkIni = Join-Path $repositoryRoot 'puredark_afw.ini'
$ofxrManifest = Join-Path $repositoryRoot `
    'XR_APILAYER_XRFrameBridge_diagnostic.json'
$ofxrIni = Join-Path $repositoryRoot 'ofxr_bridge.ini'
$optiscalerBridgeIni = Join-Path $repositoryRoot 'optiscaler_bridge.ini'
$optiscalerPayload = Join-Path $repositoryRoot 'OPTISCALER_PAYLOAD.md'
$releaseDll = Join-Path $repositoryRoot 'build/release/Release/dxgi.dll'
$launcher = Join-Path $repositoryRoot 'build/release/launcher/Release/Witcher3VRLauncher.exe'
$openXrLoaderSource = Join-Path $repositoryRoot 'external/openxr-loader'
$openXrLoaderBuild = Join-Path $repositoryRoot 'build/openxr-loader'
$openXrLoader = Join-Path $openXrLoaderBuild `
    'src/loader/Release/openxr_loader.dll'
$exampleIni = Join-Path $repositoryRoot 'witcher3vr.example.ini'
$readme = Join-Path $repositoryRoot 'README.md'
$license = Join-Path $repositoryRoot 'LICENSE'
$thirdPartyNotices = Join-Path $repositoryRoot 'THIRD_PARTY_NOTICES.md'
$stateBridgeRoot = Join-Path $repositoryRoot 'support/modWitcher3VRStateBridge'
$stateBridgeScript = Join-Path $stateBridgeRoot `
    'content/scripts/local/witcher3vr/first_person_state_bridge.ws'
$firstPersonRoot = Join-Path $repositoryRoot 'support/modWitcher3VRFirstPerson'
$firstPersonAimScript = Join-Path $firstPersonRoot `
    'content/scripts/local/witcher3vr_first_person/first_person_aim.ws'
$firstPersonHeadScript = Join-Path $firstPersonRoot `
    'content/scripts/local/witcher3vr_first_person/native_head_provider.ws'
$firstPersonStrafeScript = Join-Path $firstPersonRoot `
    'content/scripts/local/witcher3vr_first_person/on_foot_strafe.ws'
$firstPersonVisibilityScript = Join-Path $firstPersonRoot `
    'content/scripts/local/witcher3vr_first_person/player_visibility.ws'
$hudEditorRoot = Join-Path $repositoryRoot 'support/modWitcher3VRHUDEditor'
$hudEditorScript = Join-Path $hudEditorRoot `
    'content/scripts/local/witcher3vr_hud_editor/hud_editor.ws'
$hudEditorXml = Join-Path $repositoryRoot `
    'support/modWitcher3VRHUDEditor.xml'
$movementDlcRoot = Join-Path $repositoryRoot 'support/dlcmovementinputfix'
$movementDlcBundle = Join-Path $movementDlcRoot 'content/blob0.bundle'
$movementDlcMetadata = Join-Path $movementDlcRoot 'content/metadata.store'

if (-not (Test-Path -LiteralPath (Join-Path $openXrLoaderSource 'CMakeLists.txt') `
        -PathType Leaf)) {
    throw 'Missing OpenXR loader source. Run scripts/setup-dependencies.ps1 first.'
}
if (-not (Test-Path -LiteralPath $openXrLoader -PathType Leaf)) {
    & cmake -S $openXrLoaderSource -B $openXrLoaderBuild -A x64 `
        -DDYNAMIC_LOADER=ON
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to configure the pinned OpenXR loader.'
    }
    & cmake --build $openXrLoaderBuild --config Release --target openxr_loader
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to build the pinned OpenXR loader.'
    }
}

foreach ($requiredFile in @(
        $releaseDll,
        $launcher,
        $openXrLoader,
        $PureDarkPlugin,
        $pureDarkIni,
        $OfxrLayer,
        $ofxrManifest,
        $ofxrIni,
        $OptiScalerDll,
        $OptiScalerIni,
        $AmdFidelityFxDll,
        $AmdFidelityFxUpscalerDll,
        $optiscalerBridgeIni,
        $optiscalerPayload,
        $exampleIni,
        $readme,
        $license,
        $thirdPartyNotices,
        $stateBridgeScript,
        $firstPersonAimScript,
        $firstPersonHeadScript,
        $firstPersonStrafeScript,
        $firstPersonVisibilityScript,
        $hudEditorScript,
        $hudEditorXml,
        $movementDlcBundle,
        $movementDlcMetadata)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Missing release input: $requiredFile"
    }
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$stagingRoot = Join-Path $OutputDirectory '.staging'
if (Test-Path -LiteralPath $stagingRoot) {
    Remove-Item -LiteralPath $stagingRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $stagingRoot | Out-Null

try {
    $manifestLines = @("Version=$normalizedVersion")
    $commit = git -C $repositoryRoot rev-parse --verify HEAD 2>$null
    if ($LASTEXITCODE -eq 0) {
        $manifestLines += "Commit=$commit"
        $trackedChanges = git -C $repositoryRoot status --porcelain `
            --untracked-files=no
        if ($trackedChanges) {
            $manifestLines += 'Worktree=dirty'
        } else {
            $manifestLines += 'Worktree=clean'
        }
    }

    # The archive mirrors the game root. Users extract it directly into
    # "The Witcher 3" instead of manually relocating the DLL, launcher or mod.
    $releaseStage = Join-Path $stagingRoot 'game-root'
    New-Item -ItemType Directory -Path $releaseStage | Out-Null

    $binaryStage = Join-Path $releaseStage 'bin/x64_dx12'
    New-Item -ItemType Directory -Path $binaryStage | Out-Null
    Copy-Item -LiteralPath $releaseDll `
        -Destination (Join-Path $binaryStage 'dxgi.dll')
    Copy-Item -LiteralPath $launcher -Destination $binaryStage
    Copy-Item -LiteralPath $openXrLoader -Destination $binaryStage
    Copy-Item -LiteralPath $PureDarkPlugin `
        -Destination (Join-Path $binaryStage 'PDAFWPlugin.dll')
    Copy-Item -LiteralPath $pureDarkIni -Destination $binaryStage
    Copy-Item -LiteralPath $OfxrLayer -Destination `
        (Join-Path $binaryStage 'XR_APILAYER_XRFrameBridge_diagnostic.dll')
    Copy-Item -LiteralPath $ofxrManifest -Destination $binaryStage
    Copy-Item -LiteralPath $ofxrIni -Destination $binaryStage
    Copy-Item -LiteralPath $OptiScalerDll -Destination $binaryStage
    Copy-Item -LiteralPath $OptiScalerIni -Destination $binaryStage
    Copy-Item -LiteralPath $AmdFidelityFxDll -Destination $binaryStage
    Copy-Item -LiteralPath $AmdFidelityFxUpscalerDll -Destination $binaryStage
    Copy-Item -LiteralPath $optiscalerBridgeIni -Destination $binaryStage

    $modsStage = Join-Path $releaseStage 'mods'
    New-Item -ItemType Directory -Path $modsStage | Out-Null
    Copy-Item -LiteralPath $stateBridgeRoot `
        -Destination (Join-Path $modsStage 'modWitcher3VRStateBridge') -Recurse
    Copy-Item -LiteralPath $firstPersonRoot `
        -Destination (Join-Path $modsStage 'modWitcher3VRFirstPerson') -Recurse
    Copy-Item -LiteralPath $hudEditorRoot `
        -Destination (Join-Path $modsStage 'modWitcher3VRHUDEditor') -Recurse

    $configMatrixStage = Join-Path $releaseStage `
        'bin/config/r4game/user_config_matrix/pc'
    New-Item -ItemType Directory -Path $configMatrixStage -Force | Out-Null
    Copy-Item -LiteralPath $hudEditorXml -Destination $configMatrixStage

    $dlcStage = Join-Path $releaseStage 'dlc'
    New-Item -ItemType Directory -Path $dlcStage | Out-Null
    Copy-Item -LiteralPath $movementDlcRoot `
        -Destination (Join-Path $dlcStage 'dlcmovementinputfix') -Recurse

    $documentationStage = Join-Path $releaseStage 'Witcher3VR'
    $configStage = Join-Path $documentationStage 'config'
    New-Item -ItemType Directory -Path $configStage -Force | Out-Null
    Copy-Item -LiteralPath $exampleIni `
        -Destination (Join-Path $configStage 'witcher3vr.example.ini')
    Copy-Item -LiteralPath $readme -Destination $documentationStage
    Copy-Item -LiteralPath $license -Destination $documentationStage
    Copy-Item -LiteralPath $thirdPartyNotices -Destination $documentationStage
    Copy-Item -LiteralPath $optiscalerPayload -Destination $documentationStage
    Set-Content -LiteralPath (Join-Path $documentationStage 'BUILD.txt') `
        -Value @(
            $normalizedVersion,
            'One optimized DLL for gaming and diagnostics.',
            'Use Diagnostic Logging in the launcher when support logs are needed.'
        ) -Encoding utf8

    $archivePath = Join-Path $OutputDirectory "$ArtifactName.zip"
    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }
    Compress-Archive -Path (Join-Path $releaseStage '*') -DestinationPath $archivePath

    $dllHash = (Get-FileHash -LiteralPath $releaseDll -Algorithm SHA256).Hash
    $launcherHash = (Get-FileHash -LiteralPath $launcher -Algorithm SHA256).Hash
    $openXrLoaderHash =
        (Get-FileHash -LiteralPath $openXrLoader -Algorithm SHA256).Hash
    $pureDarkPluginHash =
        (Get-FileHash -LiteralPath $PureDarkPlugin -Algorithm SHA256).Hash
    $pureDarkIniHash =
        (Get-FileHash -LiteralPath $pureDarkIni -Algorithm SHA256).Hash
    $ofxrLayerHash =
        (Get-FileHash -LiteralPath $OfxrLayer -Algorithm SHA256).Hash
    $ofxrManifestHash =
        (Get-FileHash -LiteralPath $ofxrManifest -Algorithm SHA256).Hash
    $ofxrIniHash =
        (Get-FileHash -LiteralPath $ofxrIni -Algorithm SHA256).Hash
    $optiscalerDllHash =
        (Get-FileHash -LiteralPath $OptiScalerDll -Algorithm SHA256).Hash
    $optiscalerIniHash =
        (Get-FileHash -LiteralPath $OptiScalerIni -Algorithm SHA256).Hash
    $amdFidelityFxDllHash =
        (Get-FileHash -LiteralPath $AmdFidelityFxDll -Algorithm SHA256).Hash
    $amdFidelityFxUpscalerDllHash =
        (Get-FileHash -LiteralPath $AmdFidelityFxUpscalerDll -Algorithm SHA256).Hash
    $optiscalerBridgeIniHash =
        (Get-FileHash -LiteralPath $optiscalerBridgeIni -Algorithm SHA256).Hash
    $movementDlcBundleHash =
        (Get-FileHash -LiteralPath $movementDlcBundle -Algorithm SHA256).Hash
    $movementDlcMetadataHash =
        (Get-FileHash -LiteralPath $movementDlcMetadata -Algorithm SHA256).Hash
    $hudEditorScriptHash =
        (Get-FileHash -LiteralPath $hudEditorScript -Algorithm SHA256).Hash
    $hudEditorXmlHash =
        (Get-FileHash -LiteralPath $hudEditorXml -Algorithm SHA256).Hash
    $firstPersonAimHash =
        (Get-FileHash -LiteralPath $firstPersonAimScript -Algorithm SHA256).Hash
    $firstPersonHeadHash =
        (Get-FileHash -LiteralPath $firstPersonHeadScript -Algorithm SHA256).Hash
    $firstPersonStrafeHash =
        (Get-FileHash -LiteralPath $firstPersonStrafeScript -Algorithm SHA256).Hash
    $firstPersonVisibilityHash =
        (Get-FileHash -LiteralPath $firstPersonVisibilityScript -Algorithm SHA256).Hash
    $archiveHash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash
    $manifestLines += "dll.sha256=$dllHash"
    $manifestLines += "launcher.sha256=$launcherHash"
    $manifestLines += "openxr_loader.sha256=$openXrLoaderHash"
    $manifestLines += "puredark_plugin.sha256=$pureDarkPluginHash"
    $manifestLines += "puredark_ini.sha256=$pureDarkIniHash"
    $manifestLines += "ofxr_layer.sha256=$ofxrLayerHash"
    $manifestLines += "ofxr_manifest.sha256=$ofxrManifestHash"
    $manifestLines += "ofxr_ini.sha256=$ofxrIniHash"
    $manifestLines += "optiscaler.sha256=$optiscalerDllHash"
    $manifestLines += "optiscaler_ini.sha256=$optiscalerIniHash"
    $manifestLines += "amd_fidelityfx.sha256=$amdFidelityFxDllHash"
    $manifestLines += "amd_fidelityfx_upscaler.sha256=$amdFidelityFxUpscalerDllHash"
    $manifestLines += "optiscaler_bridge_ini.sha256=$optiscalerBridgeIniHash"
    $manifestLines += "movement_dlc_bundle.sha256=$movementDlcBundleHash"
    $manifestLines += "movement_dlc_metadata.sha256=$movementDlcMetadataHash"
    $manifestLines += "hud_editor_script.sha256=$hudEditorScriptHash"
    $manifestLines += "hud_editor_xml.sha256=$hudEditorXmlHash"
    $manifestLines += "first_person_aim.sha256=$firstPersonAimHash"
    $manifestLines += "first_person_head.sha256=$firstPersonHeadHash"
    $manifestLines += "first_person_strafe.sha256=$firstPersonStrafeHash"
    $manifestLines += "first_person_visibility.sha256=$firstPersonVisibilityHash"
    $manifestLines += "archive.sha256=$archiveHash"

    $manifestPath = Join-Path $OutputDirectory "$ArtifactName-SHA256.txt"
    Set-Content -LiteralPath $manifestPath -Value $manifestLines -Encoding utf8
    Write-Host "Release packages written to $OutputDirectory"
} finally {
    if (Test-Path -LiteralPath $stagingRoot) {
        Remove-Item -LiteralPath $stagingRoot -Recurse -Force
    }
}
