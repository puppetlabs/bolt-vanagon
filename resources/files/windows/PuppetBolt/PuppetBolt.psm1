Add-Type -TypeDefinition @"
public enum BoltRerunTypes
{
   All,
   Failure,
   Success
}
"@

$fso = New-Object -ComObject Scripting.FileSystemObject

$env:BOLT_BASEDIR = (Get-ItemProperty -Path "HKLM:\Software\Puppet Labs\Bolt").RememberedInstallDir
# Windows API GetShortPathName requires inline C#, so use COM instead
$env:BOLT_BASEDIR = $fso.GetFolder($env:BOLT_BASEDIR).ShortPath
$env:RUBY_DIR = $env:BOLT_BASEDIR
# Set SSL variables to ensure trusted locations are used
$env:SSL_CERT_FILE = "$($env:BOLT_BASEDIR)\ssl\cert.pem"
$env:SSL_CERT_DIR = "$($env:BOLT_BASEDIR)\ssl\certs"

function bolt {
    &$env:RUBY_DIR\bin\ruby -S -- $env:RUBY_DIR\bin\bolt ($args -replace '"', '"""')
}

function ConvertTo-BoltParameters {
    <#
    .SYNOPSIS
    This is an internal-only function used to parse powershell parameters to CLI flags
    for bolt. ConvertTo-BoltParameters takes all possible parameters optionally from
    any of the other bolt functions so that the other functions can pass @PSBoundParameters
    rather than each param one at a time.

    parameters for ConvertTo-BoltParameters does not use ValueFromPipelineByPropertyName
    intentionally, since this function is designed to only run once and produce a single
    parameter string. Pipelines should be supported by the functions that call
    ConvertTo-BoltParameters
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false)]
        [object]  $Parameters,

        [parameter(Mandatory=$false)]
        [BoltRerunTypes]  $Rerun,

        [parameter(Mandatory=$false)]
        [switch]  $Noop,

        [parameter(Mandatory=$false)]
        [string]  $Description,

        [parameter(Mandatory=$false)]
        [bool]    $SSL,

        [parameter(Mandatory=$false)]
        [bool]    $SSLVerify,

        [parameter(Mandatory=$false)]
        [bool]    $HostKeyCheck=$true,

        [parameter(Mandatory=$false)]
        [string]  $Username,

        [parameter(Mandatory=$false)]
        [string]  $Password,

        [parameter(Mandatory=$false)]
        [string]  $SSHPrivateKey,

        [parameter(Mandatory=$false)]
        [string]  $RunAs,

        [parameter(Mandatory=$false)]
        [string]  $SudoPassword,

        [parameter(Mandatory=$false)]
        [int]     $Concurrency,

        [parameter(Mandatory=$false)]
        [int]     $CompileConcurrency,

        [parameter(Mandatory=$false)]
        [string]  $ModulePath,

        [parameter(Mandatory=$false)]
        [string]  $BoltDir,

        [parameter(Mandatory=$false)]
        [string]  $ConfigFile,

        [parameter(Mandatory=$false)]
        [string]  $InventoryFile,

        [parameter(Mandatory=$false)]
        [bool]    $SaveRerun,

        [parameter(Mandatory=$false)]
        [string]  $Transport,

        [parameter(Mandatory=$false)]
        [int]     $ConnectTimeout,

        [parameter(Mandatory=$false)]
        [bool]    $TTY,

        [parameter(Mandatory=$false)]
        [string]  $Tmpdir,

        # All parameters below are unused by ConvertTo-BoltParameters, but still
        # listed here so other functions can pass @PSBoundParameters.
        [parameter(Mandatory=$false)]
        [string[]]  $TargetCommands,

        [parameter(Mandatory=$false)]
        [string[]]  $PlanNames,

        [parameter(Mandatory=$false)]
        [string[]]  $TaskNames,

        [parameter(Mandatory=$false)]
        [string[]]  $ScriptLocations,

        [parameter(Mandatory=$false)]
        [string[]]  $PuppetManifests,

        [parameter(Mandatory=$false)]
        [string]  $Source,

        [parameter(Mandatory=$false)]
        [string]  $Destination,

        [parameter(Mandatory=$false)]
        [string[]]  $Targets,

        [parameter(Mandatory=$false)]
        [string[]]  $Queries
    )
    process {
        $flags = '--format=json --no-color --verbose'
        # Actually writing debug output will require both the -Debug and -Verbose params for
        # most PS versions
        #
        # When using the -Debug automatic parameter in early versions of powershell,
        # the debug preference is set to 'inquire'. This means that if there were any Write-Debug
        # statements the cmdlet would stop and try to inquire the user if they want to continue.
        #
        # We can't really do this for bolt, since it's running in it's own process. So, unless
        # $DebugPreference is set to 'Continue' (which -Debug will _not_ set on older versions of PS)
        # we will not use Write-Debug but continue to use Write-Verbose and simply add the additional
        # --debug and --trace options to the call to bolt
        if (($DebugPreference -eq 'Inquire') -or ($DebugPreference -eq 'Continue')) {
            $flags += ' --debug --trace'
        }
        if ($Parameters -ne $null) {
            $flags += ' --params ' + "'$($Parameters | ConvertTo-Json -Compress)'"
        }
        if ($Rerun) {
            $flags += " --rerun $($Rerun.ToLower())"
        }
        if ($Noop) {
            $flags += " --noop"
        }
        if ($Description) {
            $flags += " --description $Description"
        }
        if ($SSL) {
            $flags += ' --ssl'
        } else {
            $flags += ' --no-ssl'
        }
        if ($SSLVerify) {
            $flags += ' --ssl-verify'
        } else {
            $flags += ' --no-ssl-verify'
        }
        if ($HostKeyCheck) {
            $flags += ' --host-key-check'
        } else {
            $flags += ' --no-host-key-check'
        }
        if ($Username) {
            $flags += " --user $Username"
        }
        if ($Password) {
            $flags += " --password $Password"
        }
        if ($SSHPrivateKey) {
            $flags += " --private-key $SSHPrivateKey"
        }
        if ($RunAs) {
            $flags += " --run-as $RunAs"
        }
        if ($SudoPassword) {
            $flags += " --sudo-password $SudoPassword"
        }
        if ($Concurrency) {
            $flags += " --concurrency $Concurrency"
        }
        if ($CompileConcurrency) {
            $flags += " --compile-concurrency $CompileConcurrency"
        }
        if ($ModulePath) {
            $flags += " --modulepath $ModulePath"
        }
        if ($BoltDir) {
            $flags += " --boltdir $BoltDir"
        }
        if ($ConfigFile) {
            $flags += " --configfile $ConfigFile"
        }
        if ($InventoryFile) {
            $flags += " --inventoryfile $InventoryFile"
        }
        if ($SaveRerun) {
            $flags += ' --save-rerun'
        } else {
            $flags += ' --no-save-rerun'
        }
        if ($Transport) {
            $flags += " --transport $Transport"
        }
        if ($ConnectTimeout) {
            $flags += " --connect-timeout $ConnectTimeout"
        }
        if ($TTY) {
            $flags += ' --tty'
        } else {
            $flags += ' --no-tty'
        }
        if ($Tmpdir) {
            $flags += " --tmpdir $Tmpdir"
        }
        Write-Output $flags
    }
}

function Merge-BoltOutputModulePath {
    <#
    .SYNOPSIS
    This is an internal-only function used to force the modulepath
    output from bolt to a single string. We need to treat modulepath
    differently than other parameters because it _must_ be a single
    string so when bolt attempts to execute it loads all paths in
    modulepath at once rather than one at a time.

    If we do not scrub modulepath like this we would need to allow
    modulepath to be an array in the commandlets, which can create
    unintended consequences when pipelining bolt commands together
    since the commandlet would attempt to run once for each modulepath,
    instead of only once with all modulepaths included.
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [AllowNull()]
        [AllowEmptyString()]
        [object] $BoltOutput
    )
    process {
        if ($BoltOutput.modulepath) {
            $BoltOutput.modulepath = $BoltOutput.modulepath -join ';'
        }
        Write-Output $BoltOutput
    }
}

function Invoke-BoltInternal {
    <#
    .SYNOPSIS
    This is an internal-only function used to create the bolt process and redirect standard
    error to the verbose stream and stdout to the output stream. Bolt uses stderr to print
    logging messages, so we need to redirect that to verbose so the -Verbose switch will
    work correctly with each cmdlet
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,
                   Position=0)]
        [string] $BoltCommandLine
    )
    process {
        $startInfo = New-Object System.Diagnostics.ProcessStartInfo("$env:RUBY_DIR\bin\ruby.exe", "-S -- $env:RUBY_DIR\bin\bolt $BoltCommandLine")
        $startInfo.UseShellExecute = $false
        $startInfo.CreateNoWindow = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.RedirectStandardOutput = $true
        $bolt_process = New-Object System.Diagnostics.Process
        $bolt_process.StartInfo = $startInfo
        $bolt_process.Start() | Out-Null
        # StdOut _must_ be read async or there could be deadlocks with
        # the child process while reading both StdOut and StdErr reading
        # synchronously. See "Remarks" here:
        # https://docs.microsoft.com/en-us/dotnet/api/system.diagnostics.process.standardoutput?view=netframework-4.8#remarks
        $stdout_async = $bolt_process.StandardOutput.ReadToEndAsync()
        while (!$bolt_process.HasExited) {
            if ($line = $bolt_process.StandardError.ReadLine()) {
                # Honor a value of 'Continue' for writing to debug, but nothing
                # else. If we honored 'Inquire' the cmdlet would stop and ask
                # the user to continue every time a line was read.
                if ($DebugPreference -eq 'Continue') {
                    $line | Write-Debug
                } else {
                    $line | Write-Verbose
                }
            }
        }
        $bolt_process.WaitForExit()
        $result = $stdout_async.Result
        if ($bolt_process.ExitCode -eq 0){
            $result | ConvertFrom-Json | Merge-BoltOutputModulePath | Write-Output
        } else {
            $err = ($result | ConvertFrom-Json)
            if ($err.result_error.msg) {
                $err = $err.result._error.msg
            } elseif ($err._error.msg) {
                $err = $err._error.msg
            } elseif ($err.msg) {
                $err = $err.msg
            } else {
                $err = "Bolt execution failed! re run with -Debug to see more details"
            }
            # Write the whole result to the error stream if DebugPreference is set
            if (($DebugPreference -eq 'Inquire') -or ($DebugPreference -eq 'Continue')) {
                $result | Write-Error
            }
            # intended to be caught by calling functions
            throw $err
        }
    }
}

function Invoke-BoltTask {
    <#
    .SYNOPSIS
    Execute Puppet Bolt task
    .DESCRIPTION
    This function will execute bolt tasks on the targets specified by the -Targets
    or -Queries parameter. Puppet Bolt is an agentless automation
    solution for running ad-hoc tasks and operations on remote targets
    .LINK
    https://puppet.com/products/bolt
    .LINK
    https://puppet.com/docs/bolt/latest/writing_tasks_and_plans.html
    .LINK
    https://puppet.com/docs/bolt/latest/bolt_running_tasks.html
    .LINK
    https://puppet.com/docs/bolt/latest/writing_tasks.html
    .PARAMETER TaskNames
    The names of the bolt tasks to execute
    .PARAMETER Targets
    Identifies the targets to execute on.

    Enter a string with a comma-separated list of node URIs or group names to have bolt
    execute on multiple targets at once

    Example: -Targets "localhost,node_group,ssh://nix.com:23,winrm://windows.puppet.com"
    * URI format is [protocol://]host[:port]
    * SSH is the default protocol; may be ssh, winrm, pcp, local, docker, remote
    * For Windows nodes, specify the winrm:// protocol if it has not be configured
    * For SSH, port defaults to `22`
    * For WinRM, port defaults to `5985` or `5986` based on the --[no-]ssl setting
    .PARAMETER Queries
    PuppetDB Queries to determine the targets
    .PARAMETER Parameters
    Parameters to a task or plan as:
    * a valid json string
    * powershell HashTable
    * a json file: '@<file>'

    .PARAMETER Rerun
    Retry on nodes from the last run
    * 'all' all nodes that were part of the last run.
    * 'failure' nodes that failed in the last run.
    * 'success' nodes that succeeded in the last run.
    .PARAMETER Noop
    Execute a task that supports it in noop mode
    .PARAMETER Description
    Description to use for the job
    .PARAMETER User
    User to authenticate as
    .PARAMETER Password
    Password to authenticate with. Omit the value to prompt for the password.
    .PARAMETER SSHPrivateKey
    Private ssh key to authenticate with
    .PARAMETER HostKeyCheck
    Check host keys with SSH
    .PARAMETER SSL
    Use SSL with WinRM
    .PARAMETER SSLVerify
    Verify remote host SSL certificate with WinRM
    .PARAMETER RunAs
    User to run as using privilege escalation
    .PARAMETER SudoPassword
    Password for privilege escalation. Omit the value to prompt for the password.
    .PARAMETER Concurrency
    Maximum number of simultaneous connections (default: 100)
    .PARAMETER CompileConcurrency
    Maximum number of simultaneous manifest block compiles (default: number of cores)
    .PARAMETER ModulePath
    List of directories containing modules, separated by ';'
    .PARAMETER BoltDir
    Specify what Boltdir to load config from (default: autodiscovered from current working dir)
    .PARAMETER ConfigFile
    Specify where to load config from (default: ~/.puppetlabs/bolt/bolt.yaml)
    .PARAMETER InventoryFile
    Specify where to load inventory from (default: ~/.puppetlabs/bolt/inventory.yaml)
    .PARAMETER SaveRerun
    Whether to update the rerun file after this command.
    .PARAMETER Transport
    Specify a default transport: ssh, winrm, pcp, local, docker, remote
    .PARAMETER ConnectionTimeout
    Connection timeout (defaults vary)
    .PARAMETER TTY
    Request a pseudo TTY on targets that support it
    .PARAMETER Tmpdir
    The directory to upload and execute temporary files on the target
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]  $TaskNames,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Target')]
        [string[]]  $Targets,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Query')]
        [string[]]  $Queries,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [object]  $Parameters,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [BoltRerunTypes]  $Rerun,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [switch] $Noop,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Description,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SSL=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SSLVerify=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $HostKeyCheck=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Username,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Password,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $SSHPrivateKey,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $RunAs,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $SudoPassword,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $Concurrency,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $CompileConcurrency,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ModulePath,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $BoltDir,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ConfigFile,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $InventoryFile,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SaveRerun=$false,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Transport,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $ConnectTimeout,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $TTY=$false,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Tmpdir
    )
    process {
        try {
            $bolt_params = ConvertTo-BoltParameters @PSBoundParameters
            foreach($task in $TaskNames) {
            if ($Targets) {
                    foreach ($target in $Targets) {
                        Invoke-BoltInternal -BoltCommandLine "task run $TaskNames --targets=$target $bolt_params" | Write-Output
                    }
                } else {
                    foreach ($query in $Queries) {
                        Invoke-BoltInternal -BoltCommandLine "task run $TaskNames --query=$query $bolt_params" | Write-Output
                    }
                }
            }
        } catch {
            Write-Error $_
        }
    }
}

function Invoke-BoltPlan {
    <#
    .SYNOPSIS
    Execute Puppet Bolt task plan
    .DESCRIPTION
    This function will execute bolt plans on the targets specified by the -Targets
    or -Queries parameter. Puppet Bolt is an agentless automation solution for running ad-hoc
    tasks and operations on remote targets
    .LINK
    https://puppet.com/products/bolt
    .LINK
    https://puppet.com/docs/bolt/latest/writing_tasks_and_plans.html
    .LINK
    https://puppet.com/docs/bolt/latest/bolt_running_plans.html
    .LINK
    https://puppet.com/docs/bolt/latest/writing_plans.html
    .PARAMETER PlanNames
    The names of the bolt plans to execute
    .PARAMETER Targets
    Identifies the targets to execute on.

    Enter a string with a comma-separated list of node URIs or group names to have bolt
    execute on multiple targets at once

    Example: -Targets "localhost,node_group,ssh://nix.com:23,winrm://windows.puppet.com"
    * URI format is [protocol://]host[:port]
    * SSH is the default protocol; may be ssh, winrm, pcp, local, docker, remote
    * For Windows nodes, specify the winrm:// protocol if it has not be configured
    * For SSH, port defaults to `22`
    * For WinRM, port defaults to `5985` or `5986` based on the --[no-]ssl setting
    .PARAMETER Queries
    PuppetDB Queries to determine the targets
    .PARAMETER Parameters
    Parameters to a task or plan as:
    * a valid json string
    * powershell HashTable
    * a json file: '@<file>'

    .PARAMETER Rerun
    Retry on nodes from the last run
    * 'all' all nodes that were part of the last run.
    * 'failure' nodes that failed in the last run.
    * 'success' nodes that succeeded in the last run.
    .PARAMETER Noop
    Execute a task that supports it in noop mode
    .PARAMETER Description
    Description to use for the job
    .PARAMETER User
    User to authenticate as
    .PARAMETER Password
    Password to authenticate with. Omit the value to prompt for the password.
    .PARAMETER SSHPrivateKey
    Private ssh key to authenticate with
    .PARAMETER HostKeyCheck
    Check host keys with SSH
    .PARAMETER SSL
    Use SSL with WinRM
    .PARAMETER SSLVerify
    Verify remote host SSL certificate with WinRM
    .PARAMETER RunAs
    User to run as using privilege escalation
    .PARAMETER SudoPassword
    Password for privilege escalation. Omit the value to prompt for the password.
    .PARAMETER Concurrency
    Maximum number of simultaneous connections (default: 100)
    .PARAMETER CompileConcurrency
    Maximum number of simultaneous manifest block compiles (default: number of cores)
    .PARAMETER ModulePath
    List of directories containing modules, separated by ';'
    .PARAMETER BoltDir
    Specify what Boltdir to load config from (default: autodiscovered from current working dir)
    .PARAMETER ConfigFile
    Specify where to load config from (default: ~/.puppetlabs/bolt/bolt.yaml)
    .PARAMETER InventoryFile
    Specify where to load inventory from (default: ~/.puppetlabs/bolt/inventory.yaml)
    .PARAMETER SaveRerun
    Whether to update the rerun file after this command.
    .PARAMETER Transport
    Specify a default transport: ssh, winrm, pcp, local, docker, remote
    .PARAMETER ConnectionTimeout
    Connection timeout (defaults vary)
    .PARAMETER TTY
    Request a pseudo TTY on targets that support it
    .PARAMETER Tmpdir
    The directory to upload and execute temporary files on the target
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]  $PlanNames,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Target')]
        [string[]]  $Targets,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Query')]
        [string[]]  $Queries,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [object]  $Parameters,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [BoltRerunTypes]  $Rerun,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [switch]  $Noop,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Description,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SSL=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SSLVerify=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $HostKeyCheck=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Username,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Password,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $SSHPrivateKey,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $RunAs,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $SudoPassword,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $Concurrency,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $CompileConcurrency,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ModulePath,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $BoltDir,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ConfigFile,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $InventoryFile,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SaveRerun=$false,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Transport,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $ConnectTimeout,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $TTY=$false,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Tmpdir
    )
    process {
        try {
            $bolt_params = ConvertTo-BoltParameters @PSBoundParameters
            foreach ($plan in $PlanNames) {
                if ($Targets) {
                    foreach ($target in $Targets) {
                        Invoke-BoltInternal -BoltCommandLine "plan run $plan --targets=$target $bolt_params" | Write-Output
                    }
                } else {
                    foreach ($query in $Queries) {
                        Invoke-BoltInternal -BoltCommandLine "plan run $plan --query=$query $bolt_params" | Write-Output
                    }
                }
            }
        } catch {
            Write-Error $_
        }
    }
}

function Send-BoltFile {
    <#
    .SYNOPSIS
    Execute Puppet Bolt file upload
    .DESCRIPTION
    This function will execute a bolt file upload on the targets specified by the -Targets
    or -Queries parameter. Puppet Bolt is an agentless automation
    solution for running ad-hoc tasks and operations on remote targets
    .LINK
    https://puppet.com/docs/bolt/latest/running_bolt_commands.html#concept-6839
    .LINK
    https://puppet.com/products/bolt
    .PARAMETER Source
    Location of the source file to upload
    .PARAMETER Destination
    Location on the remote target where the file should be uploaded to
    .PARAMETER Targets
    Identifies the targets to execute on.

    Enter a string with a comma-separated list of node URIs or group names to have bolt
    execute on multiple targets at once

    Example: -Targets "localhost,node_group,ssh://nix.com:23,winrm://windows.puppet.com"
    * URI format is [protocol://]host[:port]
    * SSH is the default protocol; may be ssh, winrm, pcp, local, docker, remote
    * For Windows nodes, specify the winrm:// protocol if it has not be configured
    * For SSH, port defaults to `22`
    * For WinRM, port defaults to `5985` or `5986` based on the --[no-]ssl setting
    .PARAMETER Queries
    PuppetDB Queries to determine the targets
    .PARAMETER Parameters
    Parameters to a task or plan as:
    * a valid json string
    * powershell HashTable
    * a json file: '@<file>'

    .PARAMETER Rerun
    Retry on nodes from the last run
    * 'all' all nodes that were part of the last run.
    * 'failure' nodes that failed in the last run.
    * 'success' nodes that succeeded in the last run.
    .PARAMETER Noop
    Execute a task that supports it in noop mode
    .PARAMETER Description
    Description to use for the job
    .PARAMETER User
    User to authenticate as
    .PARAMETER Password
    Password to authenticate with. Omit the value to prompt for the password.
    .PARAMETER SSHPrivateKey
    Private ssh key to authenticate with
    .PARAMETER HostKeyCheck
    Check host keys with SSH
    .PARAMETER SSL
    Use SSL with WinRM
    .PARAMETER SSLVerify
    Verify remote host SSL certificate with WinRM
    .PARAMETER RunAs
    User to run as using privilege escalation
    .PARAMETER SudoPassword
    Password for privilege escalation. Omit the value to prompt for the password.
    .PARAMETER Concurrency
    Maximum number of simultaneous connections (default: 100)
    .PARAMETER CompileConcurrency
    Maximum number of simultaneous manifest block compiles (default: number of cores)
    .PARAMETER ModulePath
    List of directories containing modules, separated by ';'
    .PARAMETER BoltDir
    Specify what Boltdir to load config from (default: autodiscovered from current working dir)
    .PARAMETER ConfigFile
    Specify where to load config from (default: ~/.puppetlabs/bolt/bolt.yaml)
    .PARAMETER InventoryFile
    Specify where to load inventory from (default: ~/.puppetlabs/bolt/inventory.yaml)
    .PARAMETER SaveRerun
    Whether to update the rerun file after this command.
    .PARAMETER Transport
    Specify a default transport: ssh, winrm, pcp, local, docker, remote
    .PARAMETER ConnectionTimeout
    Connection timeout (defaults vary)
    .PARAMETER TTY
    Request a pseudo TTY on targets that support it
    .PARAMETER Tmpdir
    The directory to upload and execute temporary files on the target
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]  $Source,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]  $Destination,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Target')]
        [string[]]  $Targets,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Query')]
        [string[]]  $Queries,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [BoltRerunTypes]  $Rerun,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [switch] $Noop,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Description,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SSL=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SSLVerify=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $HostKeyCheck=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Username,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Password,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $SSHPrivateKey,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $RunAs,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $SudoPassword,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $Concurrency,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $CompileConcurrency,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ModulePath,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $BoltDir,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ConfigFile,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $InventoryFile,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SaveRerun=$false,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Transport,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $ConnectTimeout,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $TTY=$false,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Tmpdir
    )
    process {
        try {
            $bolt_params = ConvertTo-BoltParameters @PSBoundParameters
            if ($Targets) {
                foreach ($target in $Targets) {
                    Invoke-BoltInternal -BoltCommandLine "file upload $Source $Destination --targets=$target $bolt_params" | Write-Output
                }
            } else {
                foreach ($query in $Queries) {
                    Invoke-BoltInternal -BoltCommandLine "file upload $Source $Destination --query=$query $bolt_params" | Write-Output
                }
            }
        } catch {
            Write-Error $_
        }
    }
}

function Invoke-BoltCommand {
    <#
    .SYNOPSIS
    Execute command on remote host with Puppet Bolt
    .DESCRIPTION
    This function will execute commands through bolt on the targets specified by the -Targets
    or -Queries parameter. Puppet Bolt is an agentless automation
    solution for running ad-hoc tasks and operations on remote targets
    .LINK
    https://puppet.com/products/bolt
    .LINK
    https://puppet.com/docs/bolt/latest/running_bolt_commands.html#concept-4161
    .PARAMETER TargetCommands
    The commands to execute on remote targets
    .PARAMETER Targets
    Identifies the targets to execute on.

    Enter a string with a comma-separated list of node URIs or group names to have bolt
    execute on multiple targets at once

    Example: -Targets "localhost,node_group,ssh://nix.com:23,winrm://windows.puppet.com"
    * URI format is [protocol://]host[:port]
    * SSH is the default protocol; may be ssh, winrm, pcp, local, docker, remote
    * For Windows nodes, specify the winrm:// protocol if it has not be configured
    * For SSH, port defaults to `22`
    * For WinRM, port defaults to `5985` or `5986` based on the --[no-]ssl setting
    .PARAMETER Queries
    PuppetDB Queries to determine the targets
    .PARAMETER Rerun
    Retry on nodes from the last run
    * 'all' all nodes that were part of the last run.
    * 'failure' nodes that failed in the last run.
    * 'success' nodes that succeeded in the last run.
    .PARAMETER Noop
    Execute a task that supports it in noop mode
    .PARAMETER Description
    Description to use for the job
    .PARAMETER User
    User to authenticate as
    .PARAMETER Password
    Password to authenticate with. Omit the value to prompt for the password.
    .PARAMETER SSHPrivateKey
    Private ssh key to authenticate with
    .PARAMETER HostKeyCheck
    Check host keys with SSH
    .PARAMETER SSL
    Use SSL with WinRM
    .PARAMETER SSLVerify
    Verify remote host SSL certificate with WinRM
    .PARAMETER RunAs
    User to run as using privilege escalation
    .PARAMETER SudoPassword
    Password for privilege escalation. Omit the value to prompt for the password.
    .PARAMETER Concurrency
    Maximum number of simultaneous connections (default: 100)
    .PARAMETER CompileConcurrency
    Maximum number of simultaneous manifest block compiles (default: number of cores)
    .PARAMETER ModulePath
    List of directories containing modules, separated by ';'
    .PARAMETER BoltDir
    Specify what Boltdir to load config from (default: autodiscovered from current working dir)
    .PARAMETER ConfigFile
    Specify where to load config from (default: ~/.puppetlabs/bolt/bolt.yaml)
    .PARAMETER InventoryFile
    Specify where to load inventory from (default: ~/.puppetlabs/bolt/inventory.yaml)
    .PARAMETER SaveRerun
    Whether to update the rerun file after this command.
    .PARAMETER Transport
    Specify a default transport: ssh, winrm, pcp, local, docker, remote
    .PARAMETER ConnectionTimeout
    Connection timeout (defaults vary)
    .PARAMETER TTY
    Request a pseudo TTY on targets that support it
    .PARAMETER Tmpdir
    The directory to upload and execute temporary files on the target
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]  $TargetCommands,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Target')]
        [string[]]  $Targets,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Query')]
        [string[]]  $Queries,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [BoltRerunTypes]  $Rerun,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [switch]  $Noop,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Description,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SSL=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SSLVerify=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $HostKeyCheck=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Username,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Password,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $SSHPrivateKey,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $RunAs,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $SudoPassword,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $Concurrency,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $CompileConcurrency,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ModulePath,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $BoltDir,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ConfigFile,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $InventoryFile,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SaveRerun=$false,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Transport,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $ConnectTimeout,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $TTY=$false,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Tmpdir
    )
    process {
        try {
            $bolt_params = ConvertTo-BoltParameters @PSBoundParameters
            foreach ($command in $TargetCommands) {
                if ($Targets) {
                    foreach ($target in $Targets) {
                        Invoke-BoltInternal -BoltCommandLine "command run '$command' --targets=$target $bolt_params" | Write-Output
                    }
                } else {
                    foreach ($query in $Queries) {
                        Invoke-BoltInternal -BoltCommandLine "command run '$command' --query=$query $bolt_params" | Write-Output
                    }
                }
            }
        } catch {
            Write-Error $_
        }
    }
}

function Invoke-PuppetManifestFromBolt {
    <#
    .SYNOPSIS
    Apply puppet manifests on targets with Puppet Bolt
    .DESCRIPTION
    This function will apply puppet manifests on the targets specified by the -Targets
    or -Queries parameter. Puppet Bolt is an agentless automation
    solution for running ad-hoc tasks and operations on remote targets
    .LINK
    https://puppet.com/products/bolt
    .LINK
    https://puppet.com/docs/bolt/latest/bolt_command_reference.html
    .PARAMETER PuppetManifests
    The location of the puppet manifests to apply on targets
    .PARAMETER Targets
    Identifies the targets to execute on.

    Enter a string with a comma-separated list of node URIs or group names to have bolt
    execute on multiple targets at once

    Example: -Targets "localhost,node_group,ssh://nix.com:23,winrm://windows.puppet.com"
    * URI format is [protocol://]host[:port]
    * SSH is the default protocol; may be ssh, winrm, pcp, local, docker, remote
    * For Windows nodes, specify the winrm:// protocol if it has not be configured
    * For SSH, port defaults to `22`
    * For WinRM, port defaults to `5985` or `5986` based on the --[no-]ssl setting
    .PARAMETER Queries
    PuppetDB Queries to determine the targets
   .PARAMETER Parameters
    Parameters to a task or plan as:
    * a valid json string
    * powershell HashTable
    * a json file: '@<file>'

    .PARAMETER Rerun
    Retry on nodes from the last run
    * 'all' all nodes that were part of the last run.
    * 'failure' nodes that failed in the last run.
    * 'success' nodes that succeeded in the last run.
    .PARAMETER Noop
    Execute a task that supports it in noop mode
    .PARAMETER Description
    Description to use for the job
    .PARAMETER User
    User to authenticate as
    .PARAMETER Password
    Password to authenticate with. Omit the value to prompt for the password.
    .PARAMETER SSHPrivateKey
    Private ssh key to authenticate with
    .PARAMETER HostKeyCheck
    Check host keys with SSH
    .PARAMETER SSL
    Use SSL with WinRM
    .PARAMETER SSLVerify
    Verify remote host SSL certificate with WinRM
    .PARAMETER RunAs
    User to run as using privilege escalation
    .PARAMETER SudoPassword
    Password for privilege escalation. Omit the value to prompt for the password.
    .PARAMETER Concurrency
    Maximum number of simultaneous connections (default: 100)
    .PARAMETER CompileConcurrency
    Maximum number of simultaneous manifest block compiles (default: number of cores)
    .PARAMETER ModulePath
    List of directories containing modules, separated by ';'
    .PARAMETER BoltDir
    Specify what Boltdir to load config from (default: autodiscovered from current working dir)
    .PARAMETER ConfigFile
    Specify where to load config from (default: ~/.puppetlabs/bolt/bolt.yaml)
    .PARAMETER InventoryFile
    Specify where to load inventory from (default: ~/.puppetlabs/bolt/inventory.yaml)
    .PARAMETER SaveRerun
    Whether to update the rerun file after this command.
    .PARAMETER Transport
    Specify a default transport: ssh, winrm, pcp, local, docker, remote
    .PARAMETER ConnectionTimeout
    Connection timeout (defaults vary)
    .PARAMETER TTY
    Request a pseudo TTY on targets that support it
    .PARAMETER Tmpdir
    The directory to upload and execute temporary files on the target
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]  $PuppetManifests,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Target')]
        [string[]]  $Targets,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Query')]
        [string[]]  $Queries,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [BoltRerunTypes]  $Rerun,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [switch] $Noop,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Description,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SSL=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SSLVerify=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $HostKeyCheck=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Username,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Password,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $SSHPrivateKey,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $RunAs,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $SudoPassword,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $Concurrency,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $CompileConcurrency,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ModulePath,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $BoltDir,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ConfigFile,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $InventoryFile,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SaveRerun=$false,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Transport,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $ConnectTimeout,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $TTY=$false,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Tmpdir
    )
    process {
        try {
            $bolt_params = ConvertTo-BoltParameters @PSBoundParameters
            foreach ($manifest in $PuppetManifests) {
                if ($Targets) {
                    foreach ($target in $Targets) {
                        Invoke-BoltInternal -BoltCommandLine "apply $manifest --targets=$target $bolt_params" | Write-Output
                    }
                } else {
                    foreach ($query in $Queries) {
                        Invoke-BoltInternal -BoltCommandLine "apply $manifest --query=$query $bolt_params" | Write-Output
                    }
                }
            }
        } catch {
            Write-Error $_
        }
    }
}

function Invoke-BoltScript {
    <#
    .SYNOPSIS
    Execute scripts on targets with Puppet Bolt
    .DESCRIPTION
    This function will execute scripts on the targets specified by the -Targets
    or -Queries parameter. Puppet Bolt is an agentless automation
    solution for running ad-hoc tasks and operations on remote targets
    .LINK
    https://puppet.com/products/bolt
    .LINK
    https://puppet.com/docs/bolt/latest/running_bolt_commands.html#concept-6503
    .LINK
    https://puppet.com/docs/bolt/latest/bolt_command_reference.html
    .PARAMETER ScriptLocations
    The location of the scripts to run on targets
    .PARAMETER Targets
    Identifies the targets to execute on.

    Enter a string with a comma-separated list of node URIs or group names to have bolt
    execute on multiple targets at once

    Example: -Targets "localhost,node_group,ssh://nix.com:23,winrm://windows.puppet.com"
    * URI format is [protocol://]host[:port]
    * SSH is the default protocol; may be ssh, winrm, pcp, local, docker, remote
    * For Windows nodes, specify the winrm:// protocol if it has not be configured
    * For SSH, port defaults to `22`
    * For WinRM, port defaults to `5985` or `5986` based on the --[no-]ssl setting
    .PARAMETER Queries
    PuppetDB Queries to determine the targets
    .PARAMETER Parameters
    Parameters to a task or plan as:
    * a valid json string
    * powershell HashTable
    * a json file: '@<file>'

    .PARAMETER Rerun
    Retry on nodes from the last run
    * 'all' all nodes that were part of the last run.
    * 'failure' nodes that failed in the last run.
    * 'success' nodes that succeeded in the last run.
    .PARAMETER Noop
    Execute a task that supports it in noop mode
    .PARAMETER Description
    Description to use for the job
    .PARAMETER User
    User to authenticate as
    .PARAMETER Password
    Password to authenticate with. Omit the value to prompt for the password.
    .PARAMETER SSHPrivateKey
    Private ssh key to authenticate with
    .PARAMETER HostKeyCheck
    Check host keys with SSH
    .PARAMETER SSL
    Use SSL with WinRM
    .PARAMETER SSLVerify
    Verify remote host SSL certificate with WinRM
    .PARAMETER RunAs
    User to run as using privilege escalation
    .PARAMETER SudoPassword
    Password for privilege escalation. Omit the value to prompt for the password.
    .PARAMETER Concurrency
    Maximum number of simultaneous connections (default: 100)
    .PARAMETER CompileConcurrency
    Maximum number of simultaneous manifest block compiles (default: number of cores)
    .PARAMETER ModulePath
    List of directories containing modules, separated by ';'
    .PARAMETER BoltDir
    Specify what Boltdir to load config from (default: autodiscovered from current working dir)
    .PARAMETER ConfigFile
    Specify where to load config from (default: ~/.puppetlabs/bolt/bolt.yaml)
    .PARAMETER InventoryFile
    Specify where to load inventory from (default: ~/.puppetlabs/bolt/inventory.yaml)
    .PARAMETER SaveRerun
    Whether to update the rerun file after this command.
    .PARAMETER Transport
    Specify a default transport: ssh, winrm, pcp, local, docker, remote
    .PARAMETER ConnectionTimeout
    Connection timeout (defaults vary)
    .PARAMETER TTY
    Request a pseudo TTY on targets that support it
    .PARAMETER Tmpdir
    The directory to upload and execute temporary files on the target
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]  $ScriptLocations,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Target')]
        [string[]]  $Targets,

        [parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   ParameterSetName='Query')]
        [string[]]  $Queries,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [BoltRerunTypes]  $Rerun,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [switch] $Noop,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Description,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SSL=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SSLVerify=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $HostKeyCheck=$true,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Username,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Password,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $SSHPrivateKey,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $RunAs,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $SudoPassword,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $Concurrency,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $CompileConcurrency,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ModulePath,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $BoltDir,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ConfigFile,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $InventoryFile,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $SaveRerun=$false,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Transport,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [int]     $ConnectTimeout,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [bool]    $TTY=$false,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $Tmpdir
    )
    process {
        try {
            $bolt_params = ConvertTo-BoltParameters @PSBoundParameters
            foreach ($script in $ScriptLocations) {
                if ($Targets) {
                    foreach ($target in $Targets) {
                        Invoke-BoltInternal -BoltCommandLine "script run $script --targets=$target $bolt_params" | Write-Output
                    }
                } else {
                    foreach ($query in $Queries) {
                        Invoke-BoltInternal -BoltCommandLine "script run $script --query=$query $bolt_params" | Write-Output
                    }
                }
            }
        } catch {
            Write-Error $_
        }
    }
}

function Get-BoltPlan {
    <#
    .SYNOPSIS
    Get all bolt plans available to Puppet Bolt
    .DESCRIPTION
    This function will read available plans or details
    on specific plans. Puppet Bolt is an agentless automation
    solution for running ad-hoc tasks and operations on remote targets
    .LINK
    https://puppet.com/products/bolt
    .LINK
    https://puppet.com/docs/bolt/latest/bolt_running_plans.html
    .LINK
    https://puppet.com/docs/bolt/latest/bolt_command_reference.html
    .PARAMETER PlanNames
    Names of the bolt plans to show details on
    .PARAMETER ModulePath
    List of directories containing modules, separated by ';'
    .PARAMETER BoltDir
    Specify what Boltdir to load config from (default: autodiscovered from current working dir)
    .PARAMETER ConfigFile
    Specify where to load config from (default: ~/.puppetlabs/bolt/bolt.yaml)
    #>
    [CmdletBinding()]
    param(
        [Alias("plans")]
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)]
        [string[]]  $PlanNames,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ModulePath,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $BoltDir,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ConfigFile
    )
    process {
        try {
            $bolt_params = ConvertTo-BoltParameters @PSBoundParameters
            if ($PlanNames) {
                foreach($plan in $PlanNames) {
                    Invoke-BoltInternal -BoltCommandLine "plan show $plan $bolt_params" | Write-Output
                }
            } else {
                Invoke-BoltInternal -BoltCommandLine "plan show $bolt_params" | Write-Output
            }
        } catch {
            Write-Error $_
        }
    }
}

function Get-BoltTask {
    <#
    .SYNOPSIS
    Read tasks available to Puppet Bolt
    .DESCRIPTION
    This function will get available bolt tasks or details
    on a specific task. Puppet Bolt is an agentless automation
    solution for running ad-hoc tasks and operations on remote targets
    .LINK
    https://puppet.com/products/bolt
    .LINK
    https://puppet.com/docs/bolt/latest/bolt_running_tasks.html
    .LINK
    https://puppet.com/docs/bolt/latest/bolt_command_reference.html
    .PARAMETER TaskNames
    Names of the bolt tasks to show details on
    .PARAMETER ModulePath
    List of directories containing modules, separated by ';'
    .PARAMETER BoltDir
    Specify what Boltdir to load config from (default: autodiscovered from current working dir)
    .PARAMETER ConfigFile
    Specify where to load config from (default: ~/.puppetlabs/bolt/bolt.yaml)
    #>
    [CmdletBinding()]
    param(
        [Alias("tasks")]
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true,Position=0)]
        [string[]]  $TaskNames,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ModulePath,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $BoltDir,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ConfigFile
    )
    process {
        try {
            $bolt_params = ConvertTo-BoltParameters @PSBoundParameters
            if ($TaskNames) {
                foreach($task in $TaskNames) {
                    Invoke-BoltInternal -BoltCommandLine "task show $task $bolt_params" | Write-Output
                }
            } else {
                Invoke-BoltInternal -BoltCommandLine "task show $bolt_params" | Write-Output
            }
        } catch {
            Write-Error $_
        }
    }
}

function Get-BoltModule {
    <#
    .SYNOPSIS
    Get all modules available to Puppet Bolt
    .DESCRIPTION
    This function will list all available modules to bolt.
    Puppet Bolt is an agentless automation solution for running ad-hoc
    tasks and operations on remote targets
    .LINK
    https://puppet.com/products/bolt
    .PARAMETER ModulePath
    Directories containing modules, separated by ';'
    .PARAMETER BoltDir
    Specify what Boltdir to load config from (default: autodiscovered from current working dir)
    .PARAMETER ConfigFile
    Specify where to load config from (default: ~/.puppetlabs/bolt/bolt.yaml)
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ModulePath,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $BoltDir,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ConfigFile
    )
    process {
        try {
            $bolt_params = ConvertTo-BoltParameters @PSBoundParameters
            Invoke-BoltInternal -BoltCommandLine "puppetfile show-modules $bolt_params" | Write-Output
        } catch {
            Write-Error $_
        }
    }
}

function Install-BoltModule {
    <#
    .SYNOPSIS
    Install bolt modules from puppetfile
    .DESCRIPTION
    This function will install any modules required in the puppetfile. Puppet Bolt is an agentless automation
    solution for running ad-hoc tasks and operations on remote targets
    .LINK
    https://puppet.com/products/bolt
    .LINK
    https://puppet.com/docs/bolt/latest/bolt_installing_modules.html#install-modules
    .PARAMETER ModulePath
    Directories containing modules, separated by ';'
    .PARAMETER BoltDir
    Specify what Boltdir to load config from (default: autodiscovered from current working dir)
    .PARAMETER ConfigFile
    Specify where to load config from (default: ~/.puppetlabs/bolt/bolt.yaml)
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ModulePath,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $BoltDir,

        [parameter(Mandatory=$false,ValueFromPipelineByPropertyName=$true)]
        [string]  $ConfigFile
    )
    process {
        try {
            $bolt_params = ConvertTo-BoltParameters @PSBoundParameters
            Invoke-BoltInternal -BoltCommandLine "puppetfile install $bolt_params" | Write-Output
        } catch {
            Write-Error $_
        }
    }
}

Export-ModuleMember -Function bolt -Variable *
Export-ModuleMember -Function Invoke-BoltPlan
Export-ModuleMember -Function Invoke-BoltTask
Export-ModuleMember -Function Invoke-BoltCommand
Export-ModuleMember -Function Invoke-BoltScript
Export-ModuleMember -Function Invoke-BoltApply
Export-ModuleMember -Function Send-BoltFile
Export-ModuleMember -Function Get-BoltPlan
Export-ModuleMember -Function Get-BoltTask
Export-ModuleMember -Function Get-BoltModule
Export-ModuleMember -Function Install-BoltModule
