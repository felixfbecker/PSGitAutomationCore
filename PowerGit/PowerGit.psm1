# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

using namespace System.Runtime.InteropServices

if ($psISE) {

    $actualroot=Split-Path -Path $psISE.CurrentFile.FullPath        
}
else {
    $actualroot=$PSScriptRoot
}

if (-not (Test-Path "$actualroot/Assemblies/installed")) {
    $runtime = if ($IsMacOS) {
        'osx'
    } else {
        if ($env:PROCESSOR_ARCHITECTURE="AMD64") {
        $arch = "x64"} else {
        $arch = "x86"}
        $os = if ($PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows) {
            'win'
        } elseif ($IsLinux) {
            $distro = (lsb_release --id --short).ToLower()
            $version = lsb_release --release --short
            if ($distro -eq 'debian' -and [int]$version -ge 9) {
                "$distro.9"
            } elseif ($distro -eq 'ubuntu' -and (($version -eq '16.04' -and $arch -eq 'arm64') -or ($version -eq '18.04' -and $arch -eq 'x64'))) {
                "$distro.$version"
            } elseif ($distro -eq 'alpine' -and $version -eq '3.9') {
                "$distro.$version"
            } elseif ($distro -in 'alpine','debian','rhel','fedora') {
                $distro
            } else {
                'linux'
            }
        }
        "$os-$arch"
    }

    Copy-Item "$actualroot/Assemblies/$runtime/native/*.*" "$actualroot/Assemblies/" -ErrorAction Stop
    Out-File "$actualroot/Assemblies/installed"
}

Import-Module "$actualroot/Assemblies/LibGit2Sharp.dll"
Import-Module "$actualroot/Assemblies/PowerGit.dll"

# $sshCmd = Get-Command 'ssh' -ErrorAction Ignore
# if ($sshCmd) {
#     $sshPath = $sshCmd.Path
# } else {
#     $gitCmd = Get-Command -Name 'git.exe' -ErrorAction Ignore
#     if ($gitCmd) {
#         $sshPath = Split-Path -Path $gitCmd.Path -Parent
#         $sshPath = Join-Path -Path $sshPath -ChildPath '..\usr\bin\ssh.exe' -Resolve -ErrorAction Ignore
#     }
# }

# if ($sshPath) {
#     [PowerGit.SshExeTransport]::Unregister()
#     [PowerGit.SshExeTransport]::Register($sshPath)
# } else {
#     Write-Warning -Message ('SSH support is disabled. To enable SSH, please install Git for Windows. PowerGit uses the version of SSH that ships with Git for Windows.')
# }

Get-ChildItem -Path "$actualroot/Functions", "$actualroot/Completers" -File -Filter '*.ps1' |
    ForEach-Object { . $_.FullName }
