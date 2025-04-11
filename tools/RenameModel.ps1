param (
    [string]$folderPath,
    [string]$oldModel,
    [string]$newModel
)

# Function to replace text in files
function Replace-TextInFiles {
    param (
        [string]$filePath,
        [string]$oldModel,
        [string]$newModel
    )

    Write-Host "Processing file: $filePath"
    (Get-Content $filePath) -replace $oldModel, $newModel | Set-Content $filePath
}

# Function to rename files
function Rename-Files {
    param (
        [string]$filePath,
        [string]$oldModel,
        [string]$newModel
    )

    $directory = [System.IO.Path]::GetDirectoryName($filePath)
    $fileName = [System.IO.Path]::GetFileName($filePath)
    $newFileName = $fileName

    if ($fileName -match "^\b$oldModel") {
        $newFileName = $newFileName -replace "^\b$oldModel", $newModel
    }
    if ($fileName -match "$oldModel\b$") {
        $newFileName = $newFileName -replace "$oldModel\b$", $newModel
    }

    if ($newFileName -ne $fileName) {
        $newFilePath = [System.IO.Path]::Combine($directory, $newFileName)
        Write-Host "Renaming file: $filePath to $newFilePath"
        Rename-Item -Path $filePath -NewName $newFileName
        return $newFilePath
    }
    return $filePath
}

# Function to rename folders
function Rename-Folders {
    param (
        [string]$folderPath,
        [string]$oldModel,
        [string]$newModel
    )

    $parentDir = [System.IO.Path]::GetDirectoryName($folderPath)
    $folderName = [System.IO.Path]::GetFileName($folderPath)
    $newFolderName = $folderName

    if ($folderName -match "^\b$oldModel") {
        $newFolderName = $newFolderName -replace "^\b$oldModel", $newModel
    }
    if ($folderName -match "$oldModel\b$") {
        $newFolderName = $newFolderName -replace "$oldModel\b$", $newModel
    }

    if ($newFolderName -ne $folderName) {
        $newFolderPath = [System.IO.Path]::Combine($parentDir, $newFolderName)
        Write-Host "Renaming folder: $folderPath to $newFolderPath"
        Rename-Item -Path $folderPath -NewName $newFolderName
        return $newFolderPath
    }
    return $folderPath
}

# Rename folders first to avoid path issues
$folders = Get-ChildItem -Path $folderPath -Recurse -Directory | Sort-Object -Property FullName -Descending
foreach ($folder in $folders) {
    $newFolderPath = Rename-Folders -folderPath $folder.FullName -oldModel $oldModel -newModel $newModel
    if ($newFolderPath -ne $folder.FullName) {
        Write-Host "Renamed folder: $($folder.FullName) to $newFolderPath"
    }
}

# Get all .xml and .nrproj files in the specified folder and its subfolders
$files = Get-ChildItem -Path $folderPath -Recurse -Include *.xml, *.nrproj, *.txt

foreach ($file in $files) {
    # Replace text inside the file
    Replace-TextInFiles -filePath $file.FullName -oldModel $oldModel -newModel $newModel
    
    # Rename the file if necessary
    $newFilePath = Rename-Files -filePath $file.FullName -oldModel $oldModel -newModel $newModel
    if ($newFilePath -ne $file.FullName) {
        Write-Host "Renamed file: $($file.FullName) to $newFilePath"
    }
}

# Rename the root folder if necessary
$rootFolderPath = Rename-Folders -folderPath $folderPath -oldModel $oldModel -newModel $newModel
if ($rootFolderPath -ne $folderPath) {
    Write-Host "Renamed root folder: $folderPath to $rootFolderPath"
}

Write-Host "Text replacement, file renaming, and folder renaming completed."
# Likely need to run it twice, once for folder structure once for renaming the prefix 
# Usage: .\RenameModel.ps1 -folderPath "../src/xpp/Metadata" -oldModel "ISMModel" -newModel "YOURS"
# Usage: .\RenameModel.ps1 -folderPath "../src/xpp/Metadata" -oldModel "ISM" -newModel "YOURS"