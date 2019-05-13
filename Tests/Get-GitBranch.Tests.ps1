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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-PowerGitTest.ps1' -Resolve)

Describe Get-GitBranch {
    It 'should return all branches' {
        $repo = New-GitTestRepo
        Add-GitTestFile -RepoRoot $repo -Path 'file1'
        Add-GitItem -Path (Join-Path -Path $repo -ChildPath 'file1') -RepoRoot $repo
        $c1 = Save-GitCommit -RepoRoot $repo -Message 'file1 commit'

        New-GitBranch -RepoRoot $repo -Name 'branch2'
        New-GitBranch -RepoRoot $repo -Name 'branch3'

        $branches = Get-GitBranch -RepoRoot $repo
        # Returns in lexicographical order
        $branches | ForEach-Object { $_.Tip.Sha | Should -Be $c1.Sha }
        $branches[0].Name | Should -Be 'branch2'
        $branches[0].IsCurrentRepositoryHead | Should -Be $false
        $branches[1].Name | Should -Be 'branch3'
        $branches[1].IsCurrentRepositoryHead | Should -Be $true
        $branches[2].Name | Should -Be 'master'
        $branches[2].IsCurrentRepositoryHead | Should -Be $false
    }

    It 'should throw an error when passed an invalid repository' {
        $branches = Get-GitBranch -RepoRoot 'C:\I\do\not\exist' -ErrorAction SilentlyContinue -ErrorVariable getBranchErrors
        $branches | Should -BeNullOrEmpty
        $getBranchErrors | Should -HaveCount 1
        $getBranchErrors | Should -Match 'does not exist'
    }
}
