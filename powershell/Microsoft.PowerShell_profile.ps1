Set-Alias which Get-Command
Set-Alias less more

$Env:DISPLAY = 'localhost:0.0'

Function ll() {
  Get-ChildItem -Force
}

# Merge BranchName into current branch
Function Merge-Branch([string]$BranchName) {
  git status
  if ($LastExitCode) { throw "Unable to determine git status, are you in a git repo?" }

  Set-Variable -Name "CURRENT_BRANCH" -Value (git branch --show-current)
  if (!$CURRENT_BRANCH) {
    throw "Invalid branch name. Are you sure you are in a git repo?"
  }

  git switch $BranchName
  if ($LastExitCode) { throw "Unable to switch to branch: $BranchName" }

  git pull --prune
  if ($LastExitCode) { throw "Unable to pull from remote branch: $BranchName" }

  git switch "$CURRENT_BRANCH"
  if ($LastExitCode) { throw "Unable to switch back to $CURRENT_BRANCH" }

  git merge $BranchName
  if ($LastExitCode) { throw "Unable to merge $BranchName with $CURRENT_BRANCH" }
}
Set-Alias -Name "mb" -Description "Merge a branch into current branch" -Value Merge-Branch -Force

Function Merge-Main() {
  Merge-Branch("main")
}
Set-Alias -Name "mm" -Description "Merge main into current branch" -Value Merge-Main -Force

# Creates a new branch
Function New-Branch([string]$BranchName) {
  git checkout -b "$BranchName"
}
Set-Alias -Name "bb" -Description "Creates a new branch" -Value New-Branch -Force

# Blasts away local changes
Function Reset-Hard() {
  git reset --hard
}
Set-Alias -Name "gitouttahere" -Description "Resets the current branch back to the last commit" -Value Reset-Hard -Force
Set-Alias -Name "gtfo" -Description "Resets the current branch back to the last commit" -Value Reset-Hard -Force

# Searches all files in the current directory recursively for the given pattern
Function Find-String([string]$Pattern) {
  $Files = Get-ChildItem -Recurse -File -Name -Path "."
  Foreach ($File in $Files) {
    Select-String -Path $File -Pattern $Pattern
  }
}
Set-Alias -Name "findit" -Description "Searches all files in the current directory recursively for the given pattern" -Value Find-String -Force

<#
.SYNOPSIS
    Configure PSReadLine key handlers for history search and bash-style completion.
.DESCRIPTION
    This function sets up key handlers for PSReadLine to enable history search and bash-style completion.
    It configures the up and down arrow keys to search through command history based on the current input.
    It also enables tab completion for commands, similar to Bash behavior.
.LINK
    https://github.com/PowerShell/PSReadLine
#>
Function Set-PSReadLineKeyHandlers() {
  if (!(Get-Module -Name PSReadLine -ListAvailable)) {
    Write-Host "PSReadLine module is not installed."
    return
  }

  # With these bindings, up arrow/down arrow will work like PowerShell/cmd if
  # the current command line is blank. If you've entered some text though, it
  # will search the history for commands that start with the currently entered
  # text.
  Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

  # Enable Bash-style completion
  Set-PSReadLineKeyHandler -Key Tab -Function Complete
}
Set-PSReadLineKeyHandlers
