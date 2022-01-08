Param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('AzureDevOps','GithubActions','GitLab')]
    [string] $environment = 'AzureDevOps',
    [Parameter(Mandatory=$true)]
    [string] $version,
    [Parameter(Mandatory=$false)]
    [int] $appBuild = 0,
    [Parameter(Mandatory=$false)]
    [int] $appRevision = 0
)

if ($environment -eq "AzureDevOps") {
    $buildArtifactFolder = $ENV:BUILD_ARTIFACTSTAGINGDIRECTORY
}
elseif ($environment -eq "GitHubActions") {
    $buildArtifactFolder = Join-Path $ENV:GITHUB_WORKSPACE "output"
    New-Item $buildArtifactFolder -ItemType Directory | Out-Null
}

$baseFolder = (Get-Item $ENV:GITHUB_WORKSPACE).FullName
. (Join-Path $PSScriptRoot "Read-Settings.ps1") -environment $environment -version $version
. (Join-Path $PSScriptRoot "Install-BcContainerHelper.ps1") -bcContainerHelperVersion $bcContainerHelperVersion -genericImageName $genericImageName

$params = @{}
$insiderSasToken = "$ENV:insiderSasToken"
$licenseFile = "$ENV:licenseFile"
$codeSigncertPfxFile = "$ENV:CodeSignCertPfxFile"
if (!$doNotSignApps -and $codeSigncertPfxFile) {
    if ("$ENV:CodeSignCertPfxPassword" -ne "") {
        $codeSignCertPfxPassword = try { "$ENV:CodeSignCertPfxPassword" | ConvertTo-SecureString } catch { ConvertTo-SecureString -String "$ENV:CodeSignCertPfxPassword" -AsPlainText -Force }
        $params = @{
            "codeSignCertPfxFile" = $codeSignCertPfxFile
            "codeSignCertPfxPassword" = $codeSignCertPfxPassword
        }
    }
    else {
        $codeSignCertPfxPassword = $null
    }
}

if ("$ENV:ApplicationInsightsKey" -ne "") {
    $applicationInsightKey = "$ENV:ApplicationInsightsKey"
    $params.Add("applicationInsightsKey",$applicationInsightKey)
}

if ("$ENV:ApplicationInsightsConnectionString" -ne "") {
    $applicationInsightsConnectionString = "$ENV:ApplicationInsightsConnectionString"
    $params.Add("applicationInsightsConnectionString",$applicationInsightsConnectionString)
}

$allTestResults = "testresults*.xml"
$testResultsFile = Join-Path $baseFolder "TestResults.xml"
$testResultsFiles = Join-Path $baseFolder $allTestResults
if (Test-Path $testResultsFiles) {
    Remove-Item $testResultsFiles -Force
}

Run-AlPipeline @params `
    -pipelinename $pipelineName `
    -containerName $containerName `
    -imageName $imageName `
    -artifact $artifact.replace('{INSIDERSASTOKEN}',$insiderSasToken) `
    -memoryLimit $memoryLimit `
    -baseFolder $baseFolder `
    -licenseFile $LicenseFile `
    -installApps $installApps `
    -installTestApps $installTestApps `
    -previousApps $previousApps `
    -appFolders $appFolders `
    -testFolders $testFolders `
    -doNotRunTests:$doNotRunTests `
    -testResultsFile $testResultsFile `
    -testResultsFormat 'JUnit' `
    -installTestFramework:$installTestFramework `
    -installTestLibraries:$installTestLibraries `
    -installPerformanceToolkit:$installPerformanceToolkit `
    -enableCodeCop:$enableCodeCop `
    -enableAppSourceCop:$enableAppSourceCop `
    -enablePerTenantExtensionCop:$enablePerTenantExtensionCop `
    -enableUICop:$enableUICop `
    -azureDevOps:($environment -eq 'AzureDevOps') `
    -gitLab:($environment -eq 'GitLab') `
    -gitHubActions:($environment -eq 'GitHubActions') `
    -AppSourceCopMandatoryAffixes $appSourceCopMandatoryAffixes `
    -AppSourceCopSupportedCountries $appSourceCopSupportedCountries `
    -assignPremiumPlan:$assignPremiumPlan `
    -additionalCountries $additionalCountries `
    -buildArtifactFolder $buildArtifactFolder `
    -CreateRuntimePackages:$CreateRuntimePackages `
    -appBuild $appBuild -appRevision $appRevision

if ($environment -eq 'AzureDevOps') {
    Write-Host "##vso[task.setvariable variable=TestResults]$allTestResults"
}

