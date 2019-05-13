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

function Get-GitTag {
    <#
    .SYNOPSIS
    Gets the tags in a Git repository.

    .DESCRIPTION
    The `Get-GitTag` function returns a list of all the tags in a Git repository.

    To get a specific tag, pass its name to the `Name` parameter. Wildcard characters are supported in the tag name. Only tags that match the wildcard pattern will be returned.

    .EXAMPLE
    Get-GitTag

    Demonstrates how to get all the tags in a repository.

    .EXAMPLE
    Get-GitTag -Name 'LastSuccessfulBuild'

    Demonstrates how to return a specific tag.  If no tag matches, then `$null` is returned.

    .EXAMPLE
    Get-GitTag -Name '13.8.*' -RepoRoot 'C:\Projects\PowerGit'

    Demonstrates how to return all tags that match a wildcard in the given repository.'
    #>


    [CmdletBinding()]
    [OutputType([LibGit2Sharp.Tag])]
    param(
        # Specifies which git repository to check. Defaults to the current directory.
        [Parameter()]
        [string] $RepoRoot = (Get-Location).ProviderPath,

        # The name of the tag to return. Wildcards accepted.
        [Parameter(Position = 0)]
        [string] $Name
    )

    Set-StrictMode -Version 'Latest'

    $repo = Find-GitRepository -Path $RepoRoot -Verify
    if (-not $repo) {
        return
    }
    if ($Name -and -not [WildcardPattern]::ContainsWildcardCharacters($Name)) {
        $repo.Tags[$Name]
    } else {
        $repo.Tags | Where-Object { -not $Name -or $_.FriendlyName -like $Name }
}
}
