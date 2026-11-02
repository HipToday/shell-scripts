Set-Alias which Get-Command
Set-Alias less more

$Env:DISPLAY = 'localhost:0.0'

<#
.SYNOPSIS
Lists directory contents, including hidden and system items.

.DESCRIPTION
Wrapper around Get-ChildItem that always applies the -Force option. Any
additional arguments are passed through to Get-ChildItem.

.EXAMPLE
ll

.EXAMPLE
ll C:\temp -Recurse
#>
Function ll() {
  Get-ChildItem -Force @args
}

<#
.SYNOPSIS
Compares two files in the VS Code diff viewer.

.DESCRIPTION
Wrapper around 'code --diff'. Any arguments are passed through to VS Code,
which expects the paths of the two files to compare.

.EXAMPLE
diff old.txt new.txt

Opens old.txt and new.txt side by side in VS Code.
#>
Function diff() {
  code --diff @args
}
# Remove the built-in 'diff' alias, which conflicts with the above function.
if (Get-Alias diff -ErrorAction SilentlyContinue) {
  Remove-Item Alias:diff -Force
}

<#
.SYNOPSIS
Lists all environment variables.

.DESCRIPTION
Wrapper around Get-ChildItem Env: that mimics the Unix 'env' command by
returning every environment variable in the current session.

.EXAMPLE
env

Lists all environment variables and their values.

.EXAMPLE
env | Where-Object Name -like 'PATH*'

Lists only the environment variables whose names start with PATH.

.OUTPUTS
System.Collections.DictionaryEntry
#>
Function env() {
  Get-ChildItem Env:
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

  # Set the tab completion mode options are as follows:
  #   Complete: Complete the current word and display a list of possible completions.
  #   TabCompleteNext: Cycle through the list of completions in order.
  #   TabCompletePrevious: Cycle through the list of completions in reverse order.
  #   MenuComplete: Display a menu of possible completions and allow the user to select one (Ctrl+Space default binding).
  #   PossibleCompletions: Display a list of possible completions without completing the current word.
  Set-PSReadLineKeyHandler -Key Tab -Function TabCompleteNext
}
Set-PSReadLineKeyHandlers

<#
.SYNOPSIS
Sets JAVA_HOME to the latest JDK installed alongside the current one.

.DESCRIPTION
Looks in the parent directory of CurrentJavaHome (or, if not supplied, of the
JAVA_HOME environment variable, or, if that is not set either, in
"C:\Program Files\Amazon Corretto") for the JDK directory with the highest
version and sets JAVA_HOME to it, in both the user environment (persisted) and
the current session. If the directory to search doesn't exist, or contains no
JDKs, JAVA_HOME is removed from both.

.PARAMETER CurrentJavaHome
Path of the current JDK directory. Its parent directory is searched for JDKs.

.EXAMPLE
Set-JavaHomeToLatestInstalled

.EXAMPLE
Set-JavaHomeToLatestInstalled -CurrentJavaHome 'C:\Program Files\Amazon Corretto\jdk17.0.9_9'
#>
Function Set-JavaHomeToLatestInstalled([string]$CurrentJavaHome) {
  if (!$CurrentJavaHome) { $CurrentJavaHome = $Env:JAVA_HOME }

  if ($CurrentJavaHome) {
    $JdkParentDir = Split-Path -Path $CurrentJavaHome.TrimEnd('\', '/') -Parent
  } else {
    $JdkParentDir = 'C:\Program Files\Amazon Corretto'
  }

  $Latest = $null
  if ($JdkParentDir -and (Test-Path -Path $JdkParentDir -PathType Container)) {
    # Directory names look like jdk1.8.0_392 or jdk17.0.9_9, so turn the
    # numeric part into a [version] (1.8.0.392, 17.0.9.9) for sorting.
    $Latest = Get-ChildItem -Path $JdkParentDir -Directory |
      ForEach-Object {
        if ($_.Name -match '^jdk(\d+(?:[._]\d+)*)') {
          [pscustomobject]@{ Dir = $_; Version = [version]($Matches[1] -replace '_', '.') }
        }
      } |
      Sort-Object -Property Version -Descending |
      Select-Object -First 1 -ExpandProperty Dir
  }

  $NewJavaHome = if ($Latest) { $Latest.FullName } else { $null }
  # Update the user environment (persisted) and the current session, but only
  # write when the stored value actually differs; this saves some significant
  # time/CPU cycles when updating the user environment. Passing $null as the
  # value removes the variable.
  $ChangedScopes = @()
  foreach ($Scope in 'User', 'Process') {
    if ([Environment]::GetEnvironmentVariable('JAVA_HOME', $Scope) -ne $NewJavaHome) {
      [Environment]::SetEnvironmentVariable('JAVA_HOME', $NewJavaHome, $Scope)
      $ChangedScopes += $Scope
    }
  }

  if ($ChangedScopes) {
    $ScopeText = $ChangedScopes -join ' and '
    if ($Latest) {
      Write-Host "JAVA_HOME set to $NewJavaHome ($ScopeText)"
    } else {
      Write-Host "No JDK found in '$JdkParentDir'; JAVA_HOME removed ($ScopeText)"
    }
  }
}
Set-JavaHomeToLatestInstalled

