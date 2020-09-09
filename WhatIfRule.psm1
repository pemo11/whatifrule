# Create Date: 08/09/20
# Checks if a cmdlet or functions supports whatif/confirm

using namespace System.Management.Automation.Language
using namespace Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic
function Measure-WhatIfParameter
{
<#
.SYNOPSIS
    Checks if a cmdlet or functions supports whatif/confirm

.DESCRIPTION
    To determine if command is harmful checking for whatif/confirm is a hint.
    If a command supports SupportsShouldProcess it behavior can be controlled
    by the global WhatIfPreference variable. If this variable is set to $true
    none of these command will do anything.
    If a command does not offer a whatif parameter it cannot be controlled by the
    global variable and a security concisous administrator should check these 
    commands before running the script.

.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]

.OUTPUTS
    [Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
#>
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.PowerShell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    param
    (
        # Important: The name of the parameter has to be ScriptBlockAst!
        [Parameter(Mandatory=$True)][ValidateNotNullOrEmpty()]
        [ScriptBlockAst]$ScriptBlockAst
    )
    process
    {
        $RuleResults = @()
        try
        {
            # Find all commands with a WhatIf parameter
            $Cmdlets = $ScriptBlockAst.FindAll({
               if($args[0] -is [CommandAst]){return $true}}, $true)
            foreach($Cmd in $Cmdlets)
            {
                $CmdName = $Cmd.CommandElements[0].Value
                $TestCmd = Get-Command -Name $CmdName | Where-Object { $_.Parameters.Keys -contains "WhatIf"}
                if ($null -eq $TestCmd)
                {
                    $RuleResults += [DiagnosticRecord]::new(
                        "The command $CmdName does not have a WhatIf parameter",
                        $Cmd.Extent,
                        #$PSCmdlet.MyInvocation.InvocationName
                        "WhatIf-Parameter-Rule",
                        "Information",$null
                    )
                }
            }
            return $RuleResults
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}

Export-ModuleMember -Function Measure-*