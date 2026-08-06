# A script to find release assets and upload them to the Kiwix release server.
# If run locally, you must ensure that the KIWIX_FILE_UPLOAD_SSH_KEY secret to access the release server is available in
# your File System, as scripts/upload_ssh_key (this is the file the workflow writes the secret to).
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
    $releaseAssets = @()
    if ($release.assets) {
        $release.assets | % {
            $asset = $_
            if ($asset.name -imatch $rgxAssetMatch) {
                $assetUrl = $asset.browser_download_url
                $releaseAssets += $asset
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
    if ($releaseAssets.count) {
        $releaseAssets | % {
            $asset = $_
            if (! $dryrun) {
                # NB the Accept header is essential: without it, the API returns the asset's JSON
                # metadata instead of the binary, and we would upload that in place of the archive
                $asset_params = @{
                    Uri = $asset.url
                    OutFile = $asset.name
                    Headers = @{ 'Accept' = 'application/octet-stream' }
                }
                Invoke-WebRequest @asset_params
            }
            # Check we got the whole binary, not an error page or the asset's JSON metadata
            $downloaded = $null
            if (Test-Path $asset.name -PathType leaf) { $downloaded = Get-Item $asset.name }
            if (($downloaded -and ($downloaded.Length -eq $asset.size)) -or $dryrun) {
                if ($dryrun) { "[DRYRUN]:"}
                Write-Host "`n* Downloaded asset" $asset.name "to local file system..." -ForegroundColor Green
                $releaseFiles += $asset.name # Store the filename to access when we upload
            } else {
                Write-Host "`n** The file" $asset.name "does not appear to have downloaded correctly! **" -ForegroundColor Red
                if ($downloaded) {
                    Write-Host "** Expected" $asset.size "bytes, but got" $downloaded.Length "bytes **`n" -ForegroundColor Red
                }
                $errorFlag = $true
            }
        }
        if ($errorFlag) {
            exit 1
        }
    } else {
        ""
        Write-Warning "No assets of Release" $release.id "($tag) match $rgxAssetMatch!"
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
        $keyfile = "$PSScriptRoot\upload_ssh_key"
        $keyfile = $keyfile -ireplace '[\\/]', '/'
        ""
        $releaseFiles | % {
            $filename = $_
            if ($dryrun) {
                "[DRYRUN] C:\Program Files\Git\usr\bin\scp.exe -P 30322 -o StrictHostKeyChecking=no -i $keyfile $filename javascript-libzim@${server}:$target"
                Write-Warning "No file was uploaded because this is a dry run.`n"
            } else {
                # Uploading file
                & "C:\Program Files\Git\usr\bin\scp.exe" @('-P', '30322', '-o', 'StrictHostKeyChecking=no', '-i', "$keyfile", "$filename", "javascript-libzim@${server}:$target")
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
