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

function Get-GitCommit {
    <#
    .SYNOPSIS
    Gets the sha-1 ID for specific changes in a Git repository.

    .DESCRIPTION
    The `Get-GitCommit` gets all the commits in a repository, from most recent to oldest.

    To get a commit for a specific named revision, e.g. HEAD, a branch, a tag), pass the name to the `Revision` parameter.

    To get the commit of the current checkout, pass `HEAD` to the `Revision` parameter.
    #>
    [CmdletBinding(DefaultParameterSetName = 'CommitFilter')]
    [OutputType([LibGit2Sharp.Commit])]
    param(
        # Get all the commits in the repository.
        [Parameter(ParameterSetName = 'All')]
        [switch] $All,

        # A named revision to get, e.g. `HEAD`, a branch name, tag name, etc.
        # To get the commit of the current checkout, pass `HEAD`.
        [Parameter(Mandatory, Position = 0, ParameterSetName = 'Lookup')]
        [string] $Revision,

        # The starting commit from which to generate a list of commits. Defaults to `HEAD`.
        [Parameter(ParameterSetName = 'CommitFilter')]
        [string] $Since = 'HEAD',

        # The commit and its ancestors which will be` excluded from the returned commit list which starts at `Since`.
        [Parameter(ParameterSetName = 'CommitFilter')]
        [string] $Until,

        # Do not include any merge commits in the generated commit list.
        [Parameter(ParameterSetName = 'CommitFilter')]
        [switch] $NoMerges,

        # The path to the repository. Defaults to the current directory.
        [string] $RepoRoot
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $repo = Find-GitRepository -Path $RepoRoot
    if (-not $repo) {
        return
    }

    $commits = if ($PSCmdlet.ParameterSetName -eq 'All') {
        $filter = New-Object -TypeName 'LibGit2Sharp.CommitFilter'
        $filter.IncludeReachableFrom = $repo.Refs
        $repo.Commits.QueryBy($filter)
    } elseif ($PSCmdlet.ParameterSetName -eq 'Lookup') {
        $change = $repo.Lookup($Revision)
        if ($change) {
            $change
        } else {
            Write-Error -Message ('Commit ''{0}'' not found in repository ''{1}''.' -f $Revision, $repo.Info.WorkingDirectory) -ErrorAction $ErrorActionPreference
            return
        }
    } elseif ( $PSCmdlet.ParameterSetName -eq 'CommitFilter') {
        $IncludeFromCommit = $repo.Lookup($Since)

        if (-not $IncludeFromCommit) {
            Write-Error -Message ('Commit ''{0}'' not found in repository ''{1}''.' -f $Since, $repo.Info.WorkingDirectory) -ErrorAction $ErrorActionPreference
            return
        }

        $CommitFilter = [LibGit2Sharp.CommitFilter]::new()
        $CommitFilter.IncludeReachableFrom = $IncludeFromCommit.Sha

        if ($Until) {
            $ExcludeFromCommit = $repo.Lookup($Until)
            if (-not $ExcludeFromCommit) {
                Write-Error -Message ('Commit ''{0}'' not found in repository ''{1}''.' -f $Until, $repo.Info.WorkingDirectory) -ErrorAction $ErrorActionPreference
                return
            }
            if ($IncludeFromCommit.Sha -eq $ExcludeFromCommit.Sha) {
                Write-Error -Message ('Commit reference ''{0}'' and ''{1}'' refer to the same commit with hash ''{2}''.' -f $Since, $Until, $IncludeFromCommit.Sha)
                return
            }
            $CommitFilter.ExcludeReachableFrom = $ExcludeFromCommit.Sha
        }

        $filteredCommits = $repo.Commits.QueryBy($CommitFilter)

        if ($NoMerges) {
            $filteredCommits = $filteredCommits | Where-Object { $_.Parents.Count -le 1 }
    }

    $filteredCommits
}
$commits
}
