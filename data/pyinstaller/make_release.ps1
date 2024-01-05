# Scripts to build a onedir PyInstaller versions of the plaso tools.
# The tools are bundled into a single ZIP file.

# Note that Param must be called first.
# Usage: .\make_release.ps1 -Architecture win32
Param (
	[string]$Architecture = "amd64",
	[string]$PythonPath = ""
)

If ( $Architecture -eq "x86" )
{
	$Architecture = "win32"
}
If ( -not $PythonPath )
{
	If ( $Architecture -eq "win32" )
	{
		$PythonPath = "C:\Python311-32"
	}
	Else
	{
		$PythonPath = "C:\Python311-64"
	}
}

Try
{
	# -ErrorAction Stop causes Get-Command to raise a non-terminating
	# exception. A non-terminating exception will not be caught by
	# try-catch.
	$PyInstaller = (Get-Command "pyinstaller.exe" -ErrorAction Stop).Path
	$Python = ""
}
Catch
{
	$PyInstaller = "pyinstaller.exe"
}

If (-Not (Test-Path $PyInstaller))
{
	$PyInstaller = "..\pyinstaller\pyinstaller.py"

	If (-Not (Test-Path $PyInstaller))
	{
	    Write-Host "Missing PyInstaller." -foreground Red

	    Exit 1
	}
	$Python = "${PythonPath}\python.exe"

	If (-Not (Test-Path $Python))
	{
	    Write-Host "Missing Python: ${Python}." -foreground Red

	    Exit 1
	}
}

$Version = & Invoke-Expression -Command "git describe --tags --abbrev=0 2>&1"

# Build the binaries for each tool
If (Test-Path "dist")
{
    Remove-Item -Force -Recurse "dist"
}
If ( $Python -ne "" )
{
	# Note that the double quotes in the Python command are escaped by using double quotes
	$PythonVersion = & Invoke-Expression -Command "& '${Python}' -c ""from __future__ import print_function; import sys; print('{0:d}.{1:d}'.format(sys.version_info[0], sys.version_info[1]))"" "
}
Else
{
	$PythonVersion = ""
}
If ( $PythonVersion -ne "" )
{
	$PythonVersion = "-py${PythonVersion}"
}

$Arguments = "--onedir tools\image_export.py" + ('future','psutil','pycreg','redis','zmq' | ForEach-Object { " --hidden-import " + $_ })

If ( $Python -ne "" )
{
	$Output = Invoke-Expression -Command "& '${Python}' ${PyInstaller} ${Arguments} 2>&1"
}
Else
{
	$Output = Invoke-Expression -Command "${PyInstaller} ${Arguments} 2>&1"
}
If ( $LastExitCode -ne 0 ) {
    Write-Host "Error running PyInstaller for tools\image_export.py." -foreground Red
    Write-Host ${Output} -foreground Red
    Exit 1
}
Else
{
	Write-Host ${Output}
}

$Arguments = "--onedir tools\log2timeline.py" + ('future' | ForEach-Object { " --hidden-import " + $_ })

If ( $Python -ne "" )
{
	$Output = Invoke-Expression -Command "& '${Python}' ${PyInstaller} ${Arguments} 2>&1"
}
Else
{
	$Output = Invoke-Expression -Command "${PyInstaller} ${Arguments} 2>&1"
}
If ( $LastExitCode -ne 0 ) {
    Write-Host "Error running PyInstaller for tools\log2timeline.py." -foreground Red
    Write-Host ${Output} -foreground Red
    Exit 1
}
Else
{
	Write-Host ${Output}
}

$Arguments = "--onedir tools\pinfo.py" + ('bencode','defusedxml','future','lz4','pefile','psutil','zmq' | ForEach-Object { " --hidden-import " + $_ })

If ( $Python -ne "" )
{
	$Output = Invoke-Expression -Command "& '${Python}' ${PyInstaller} ${Arguments} 2>&1"
}
Else
{
	$Output = Invoke-Expression -Command "${PyInstaller} ${Arguments} 2>&1"
}
If ( $LastExitCode -ne 0 ) {
    Write-Host "Error running PyInstaller for tools\pinfo.py." -foreground Red
    Write-Host ${Output} -foreground Red
    Exit 1
}
Else
{
	Write-Host ${Output}
}

$Arguments = "--onedir tools\psort.py" + ('bencode','defusedxml','future','lz4','pefile' | ForEach-Object { " --hidden-import " + $_ })

If ( $Python -ne "" )
{
	$Output = Invoke-Expression -Command "& '${Python}' ${PyInstaller} ${Arguments} 2>&1"
}
Else
{
	$Output = Invoke-Expression -Command "${PyInstaller} ${Arguments} 2>&1"
}
If ( $LastExitCode -ne 0 ) {
    Write-Host "Error running PyInstaller for tools\psort.py." -foreground Red
    Write-Host ${Output} -foreground Red
    Exit 1
}
Else
{
	Write-Host ${Output}
}

$Arguments = "--onedir tools\psteal.py" + ('future' | ForEach-Object { " --hidden-import " + $_ })


If ( $Python -ne "" )
{
	$Output = Invoke-Expression -Command "& '${Python}' ${PyInstaller} ${Arguments} 2>&1"
}
Else
{
	$Output = Invoke-Expression -Command "${PyInstaller} ${Arguments} 2>&1"
}
If ( $LastExitCode -ne 0 ) {
    Write-Host "Error running PyInstaller for tools\psteal.py." -foreground Red
    Write-Host ${Output} -foreground Red
    Exit 1
}
Else
{
	Write-Host ${Output}
}

# Set up distribution package path
$DistPath = "dist\plaso"

If (Test-Path "${DistPath}")
{
    Remove-Item -Force -Recurse "${DistPath}"
}
New-Item -ItemType "directory" -Path "${DistPath}"
New-Item -ItemType "directory" -Path "${DistPath}\licenses"

Copy-Item -Force ACKNOWLEDGEMENTS "${DistPath}"
Copy-Item -Force AUTHORS "${DistPath}"
Copy-Item -Force LICENSE "${DistPath}"
Copy-Item -Force README "${DistPath}"

Copy-Item -Force -Recurse "dist\image_export\*" "${DistPath}"
Copy-Item -Force -Recurse "dist\log2timeline\*" "${DistPath}"
Copy-Item -Force -Recurse "dist\pinfo\*" "${DistPath}"
Copy-Item -Force -Recurse "dist\psort\*" "${DistPath}"
Copy-Item -Force -Recurse "dist\psteal\*" "${DistPath}"

# Copy the license files of the dependencies
$Output = Invoke-Expression -Command "git.exe clone https://github.com/log2timeline/l2tdevtools dist\l2tdevtools 2>&1"

$dep = Get-Content dist\l2tdevtools\data\presets.ini | Select-String -pattern '\[plaso\]' -context 0,1
Foreach ($d in $dep.context.DisplayPostContext.split(': ')[2].split(',')) {
    Copy-Item -Force "dist\l2tdevtools\data\licenses\LICENSE.$($d)" ${DistPath}\licenses
}

$DistPath = "${DistPath}\_internal"
New-Item -ItemType "directory" -Path "${DistPath}\data"
Copy-Item -Force -Recurse "data\*" "${DistPath}\data"

# Copy the artifacts yaml files
$Output = Invoke-Expression -Command "git.exe clone https://github.com/ForensicArtifacts/artifacts.git dist\artifacts 2>&1"

Push-Location "dist\artifacts"

Try
{
	$LatestTag = Invoke-Expression -Command "git.exe describe --tags $(git.exe rev-list --tags --max-count=1) 2>&1"
	$Output = Invoke-Expression -Command "git.exe checkout ${LatestTag} 2>&1"
}
Finally
{
	Pop-Location
}
New-Item -ItemType "directory" -Path "${DistPath}\artifacts"

Copy-Item -Force "dist\artifacts\artifacts\data\*.yaml" "${DistPath}\artifacts"

# Copy the dfVFS yaml (dtFabric definition) files
$Output = Invoke-Expression -Command "git.exe clone https://github.com/log2timeline/dfvfs.git dist\dfvfs 2>&1"

Push-Location "dist\dfvfs"

Try
{
	$LatestTag = Invoke-Expression -Command "git.exe describe --tags $(git.exe rev-list --tags --max-count=1) 2>&1"
	$Output = Invoke-Expression -Command "git.exe checkout ${LatestTag} 2>&1"
}
Finally
{
	Pop-Location
}
New-Item -ItemType "directory" -Path "${DistPath}\dfvfs\lib"

Copy-Item -Force "dist\dfvfs\dfvfs\lib\*.yaml" "${DistPath}\dfvfs\lib"

# Copy the dfWinReg yaml (dtFabric definition) files
$Output = Invoke-Expression -Command "git.exe clone https://github.com/log2timeline/dfwinreg.git dist\dfwinreg 2>&1"

Push-Location "dist\dfwinreg"

Try
{
	$LatestTag = Invoke-Expression -Command "git.exe describe --tags $(git.exe rev-list --tags --max-count=1) 2>&1"
	$Output = Invoke-Expression -Command "git.exe checkout ${LatestTag} 2>&1"
}
Finally
{
	Pop-Location
}
New-Item -ItemType "directory" -Path "${DistPath}\dfwinreg"

Copy-Item -Force "dist\dfwinreg\dfwinreg\*.yaml" "${DistPath}\dfwinreg"

# Copy the plaso yaml (dtFabric definition) files
Get-ChildItem -Path "plaso\" -Recurse -Include "*.yaml" | Foreach-Object {
	$source = ($_ | Resolve-Path -Relative ) -replace "^\.\\",""
	$destination = "${DistPath}\$(Split-Path -Path $source)"
	if(!(Test-Path $destination)) { $null = New-Item -ItemType "directory" -Path "$destination" }
	Copy-Item $source -Destination "${DistPath}\$source" -Force
}


# Makes plaso-<version><python_version>-<architecture>.zip
Add-Type -assembly "system.io.compression.filesystem"
$PlasoPath = $(pwd | % Path)
$ArchivePath = "${PlasoPath}\plaso-${Version}${PythonVersion}-${Architecture}.zip"
if(Test-Path $ArchivePath) { Remove-Item $ArchivePath }
[io.compression.zipfile]::CreateFromDirectory("${PlasoPath}\dist\plaso", "${PlasoPath}\plaso-${Version}${PythonVersion}-${Architecture}.zip")
