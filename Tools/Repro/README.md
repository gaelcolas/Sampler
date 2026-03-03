# Reproducibility helpers (optional)

Small, additive helpers for capturing run metadata and comparing output folders.

## New-RunManifest.ps1

Writes `manifest.json` to an output directory (tool/run id/inputs + host info + optional git metadata).

Example:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File Tools/Repro/New-RunManifest.ps1 `
  -OutDir "./out/run_001" `
  -ToolName "Sampler" `
  -RunId "run_001" `
  -Inputs @{ task="build"; configuration="Release" } `
  -RepoPath "./"
```

## Compare-RunFolders.ps1

Compares two folders using SHA256 + size per file and writes `compare_report.json` + `compare_report.md`.

Example:

```powershell
pwsh -NoProfile -ExecutionPolicy Bypass -File Tools/Repro/Compare-RunFolders.ps1 `
  -A "./out/run_001" `
  -B "./out/run_002" `
  -OutDir "./out/compare_001_002"
```

---

Related: https://github.com/vgplatformproject
