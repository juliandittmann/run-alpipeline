[![main-CI](https://github.com/juliandittmann/run-alpipeline/actions/workflows/main.yml/badge.svg)](https://github.com/juliandittmann/run-alpipeline/actions/workflows/main.yml)

# run-alpipeline

This is a github action to run an AL pipeline.

## Usage

```
name: CI

on: [push]

env:
  version: ci
  appVersion: '18.0'
  appBuild: ${{github.run_number}}
  appRevision: 0

defaults:
  run:
    shell: PowerShell

jobs:
  build:
    runs-on: windows-latest

    steps:
      - uses: actions/checkout@v2

      - name: Run pipeline
        uses: juliandittmann/run-alpipeline@v0.1
        with:
          version: ${{env.version}}
          appVersion: ${{env.appVersion}}
          appBuild: ${{env.appBuild}}
          appRevision: ${{env.appRevision}}
          InsiderSasToken: ${{ secrets.InsiderSasToken }}
          LicenseFile: ${{ secrets.LicenseFile }}
          CodeSignCertPfxFile: ${{ secrets.CodeSignCertPfxFile }}
          CodeSignCertPfxPassword: ${{ secrets.CodeSignCertPfxPassword }}
```
     
## Example 

You can find an example [here](https://github.com/juliandittmann/AL.Template).
