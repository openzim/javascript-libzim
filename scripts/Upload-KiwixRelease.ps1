# A script to find release assets and upload them to the Kiwix release server.
# If run loaclly, you must ensure that the SSH_KEY secret to access the release server is available in your File System.
# You should also provide the tag version as input to this script, or set the $version variable to an existing release tag.

param (
    [string]$tag = "",
    [switch]$dryrun = $false,
    [switch]$yes = $false,
    [switch]$help = $false
)

# DEV: Ensure these values are correctly set
$server = "master.download.kiwix.org"
$target = "/data/openzim/release/javascript-libzim" # No final slash!
$rgxAssetMatch = "^libzim.+?[0-9.]+\.zip" # A regular expression to match the type of asset to upload
if (! $repository) {
    $repository = "openzim/javascript-libzim"
}
$releaseAPI = "https://api.github.com/repos/$repository/releases" # No final slash!

function Main {
    # If a version is already set (e.g. by GitHub Actions release event), then use it
    if ($version) { $tag = $version }
    # Deal with cases where no tag is entered
    if (($tag -eq "") -and (!$help)) { 
        $tag = Read-Host "`nEnter the tag corresponding to the version to upload to Kiwix or ? for help"
        if ($tag -eq "") {
            Write-Warning "You must enter a tag!`n"
            exit
        }
    }
    # Check whether user asked for help
    if (($tag -eq "?") -or ($help)) {
        Get-PushHelp
        exit
    }
    # Get the release if we don't have it
    if (! $release) {
        $release_params = @{
            Uri = $releaseAPI
            Method = 'GET'
            Headers = @{
                # 'Authorization' = "token $GITHUB_TOKEN"
                'Accept' = 'application/vnd.github.v3+json'
            }
            ContentType = "application/json"
        }
        echo $release_params
        $releases = Invoke-RestMethod @release_params
        $release_found = $false
        $release = $null
        $releases | Where-Object { $release_found -eq $False } | % {
            $release = $_
            if ($release.tag_name -match $tag) {
                $release_found = $true
            }
        }
        if ($release_found) {
            if ($dryrun) {
                $release_json = $release | ConvertTo-Json
                "[DRYRUN:] Relase found for tag ${tag}: `n$release_json"
            }
        } else {
            ""
            Write-Warning "No release matching the tag $tag was found."
            exit 1
        }
    }
    # We should have a release, so now get the assets
    $releaseAssetsURLs = @()
    if ($release.assets) {
        $release.assets | % {
            $asset = $_
            if ($asset.name -imatch $rgxAssetMatch) {
                $assetUrl = $asset.url + "/" + $asset.name
                $releaseAssetsURLs += $assetUrl
                Write-Host "Found asset $assetUrl!" -ForegroundColor Green
            }
        }
    } else {
        ""
        Write-Warning "Release id " + $release.id + " (corresponding to $tag) does not appear to have any assets!"
        exit 1
    }
    # If we found assets, download them to file system
    $releaseFiles = @()
    $errorFlag = $false
    if ($releaseAssetsURLs.count) {
        $releaseAssetsURLs | % {
            $filename = ($_ -replace "^.+/", "")
            if (! $dryrun) {
                Invoke-WebRequest $_ -OutFile $filename
            }
            if ((Test-Path $filename -PathType leaf) -or $dryrun) {
                if ($dryrun) { "[DRYRUN]:"}
                Write-Host "Downloaded asset $filename to local file system..." -ForegroundColor Green
                $releaseFiles += $filename # Store the filename to access when we upload
            } else {
                Write-Host "`n** The file $filename does not appear to have downloaded correctly! **`n" -ForegroundColor Red
                $errorFlag = $true
            }
        }
        if ($errorFlag) {
            exit 1
        }
    } else {
        ""
        Write-Warning "No assets of Release " + $release.id + " ($tag) match $rgxAssetMatch!"
        exit 1
    }
    # We should have filenames and files now, so upload to Kiwix
    if ($releaseFiles.count -or $dryrun) {
        # If the path is a file of the right type, ask for confirmation 
        "`nFiles are ready to upload to $target ..."
        if ($dryrun) { "DRY RUN: no upload will be made" }
        if (! $yes) {
            $response = Read-Host "Do you wish to proceed? Y/N"
            if ($response -ne "Y") {
                ""
                Write-Warning "Aborting upload because user cancelled."
                exit
            }
        }
        # Load the secret
        $keyfile = "$PSScriptRoot\ssh_key"
        $keyfile = $keyfile -ireplace '[\\/]', '/'
        ""
        $releaseFiles | % {
            $filename = $_
            if ($dryrun) {
                "[DRYRUN] C:\Program Files\Git\usr\bin\scp.exe -P 30022 -o StrictHostKeyChecking=no -i $keyfile $filename ci@${server}:$target"
                Write-Warning "No file was uploaded because this is a dry run.`n"
            } else {
                # Uploading file
                & "C:\Program Files\Git\usr\bin\scp.exe" @('-P', '30022', '-o', 'StrictHostKeyChecking=no', '-i', "$keyfile", "$filename", "ci@${server}:$target")
                Write-Host "`nUploaded $filename to $server$target"
            }
        }
    } else {
        # This shouldn't happen!
        Write-Host "`nERROR! We don't seem to have any filenames to upload!" -ForegroundColor Red
        exit 1
    }
}

function Get-PushHelp {
@"

    Usage: .\Upload-KiwixRelease TAG or ? [-dryrun] [-tag] [-yes] [-help] 
    
    Uploads release assets to $server/$target
    
    TAG or ?    the tag of the version to upload, or ? for help
    -dryrun     tests that the file exists and is of the right type, but does not upload it
    -yes        skip confirmation of upload 
    -help       prints these instructions
    
"@
}
# Ensure script starts from root directory
cd $PSScriptRoot/..
# Run the main script
Main
