function Edit-TenPluginRule {
    <#
    .SYNOPSIS
        Edits a Nessus plugin rule

    .DESCRIPTION
        Can be used to change a previously defined, scan report altering rule

    .PARAMETER SessionId
        ID of a valid Nessus session. This is auto-populated after a connection is made using Connect-TenServer.

    .PARAMETER Id
        ID number of the rule which would you like removed/deleted

    .PARAMETER PluginId
        ID number of the plugin which would you like altered

    .PARAMETER ComputerName
        Name, IP address, or Wildcard (*), which defines the the host(s) affected by the rule

    .PARAMETER Type
        Severity level you would like future scan reports to display for the defined host(s)

    .PARAMETER Expiration
        Date/Time object, which defines the time you would like the rule to expire. Not required

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        PS> Edit-TenPluginRule -SessionId 0 -Id 500 -ComputerName 'YourComputer' -Expiration (([datetime]::Now).AddDays(10)) -Type Low

        Will edit a plugin rule with an ID of 500, to have a new computer name. Rule expires in 10 days

    .EXAMPLE
        PS> Get-TenPluginRule -SessionId 0 | Edit-TenPluginRule -Type High

        Will alter all rules to now have a serverity of 'Info'

    .EXAMPLE
        PS> Get-TenPluginRule -SessionId 0 | ? {$_.Host -eq 'myComputer'} | Edit-TenPluginRule -Type 'High'

        Will find all plugin rules that match the computer name, and set their severity to high
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('Index')]
        [int32]$SessionId,
        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [int32]$Id,
        [Parameter(Mandatory, Position = 2, ValueFromPipelineByPropertyName)]
        [int32]$PluginId,
        [Parameter(Position = 3, ValueFromPipelineByPropertyName)]
        [Alias('IPAddress', 'IP', 'Host')]
        [String]$ComputerName = '*',
        [Parameter(Mandatory, Position = 4, ValueFromPipelineByPropertyName)]
        [ValidateSet('Critical', 'High', 'Medium', 'Low', 'Info', 'Exclude')]
        [String]$Type,
        [Parameter(Position = 5, ValueFromPipelineByPropertyName)]
        [Object]$Expiration, #TODO: Validate the Expiratoin date, but still allow nulls
        [switch]$EnableException
    )
    process {
        foreach ($session in (Get-TenSession -SessionId $SessionId)) {

            $dtExpiration = $null

            If ($Expiration) {
                $dtExpiration = (New-TimeSpan -Start $origin -end $Expiration -ErrorAction SilentlyContinue).TotalSeconds.ToInt32($null)
            }

            $dicType = @{
                'Critical' = 'recast_critical'
                'High'     = 'recast_high'
                'Medium'   = 'recast_medium'
                'Low'      = 'recast_low'
                'Info'     = 'recast_info'
                'Exclude'  = 'exclude'
            }

            $strType = $dicType[$Type]

            $pRulehash = @{
                'plugin_id' = $PluginId
                'host'      = $ComputerName
                'type'      = $strType
            }

            If ($dtExpiration) {
                $pRulehash.Add('date', $dtExpiration)
            }

            $pRuleJson = ConvertTo-Json -InputObject $pRulehash -Compress

            $params = @{
                SessionObject   = $session
                Path            = ('/plugin-rules/{0}' -f $Id)
                Method          = 'Put'
                Parameter       = $pRuleJson
                ContentType     = 'application/json'
                EnableException = $EnableException
            }

            Invoke-TenRequest @params
        }
    }
}