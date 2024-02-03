Function Get-BlockRulesMeta {
    <#
    .SYNOPSIS
        Gets the latest Microsoft Recommended block rules, removes its allow all rules and sets HVCI to strict
    .INPUTS
        None. You cannot pipe objects to this function.
    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()
    # Importing the $PSDefaultParameterValues to the current session, prior to everything else
    . "$ModuleRootPath\CoreExt\PSDefaultParameterValues.ps1"

    # Importing the required sub-modules
    Import-Module -FullyQualifiedName "$ModuleRootPath\Shared\Write-ColorfulText.psm1" -Force
   
    # Download the markdown page from GitHub containing the latest Microsoft recommended block rules 
    [System.String]$MSFTRecommendedBlockRulesAsString = (Invoke-WebRequest -Uri $MSFTRecommendedBlockRulesURL -ProgressAction SilentlyContinue).Content

    # Load the Block Rules as XML into a variable after extracting them from the markdown string
    [System.Xml.XmlDocument]$BlockRulesXML = ($MSFTRecommendedBlockRulesAsString -replace "(?s).*``````xml(.*)``````.*", '$1').Trim()
        
    # Get the SiPolicy node
    [System.Xml.XmlElement]$SiPolicyNode = $BlockRulesXML.SiPolicy

    # Declare the namespace manager and add the default namespace with a prefix
    [System.Xml.XmlNamespaceManager]$NameSpace = New-Object -TypeName System.Xml.XmlNamespaceManager -ArgumentList $BlockRulesXML.NameTable
    $NameSpace.AddNamespace('ns', 'urn:schemas-microsoft-com:sipolicy')

    # Select the FileRuleRef nodes that have a RuleID attribute that starts with ID_ALLOW_
    [System.Object[]]$NodesToRemove = $SiPolicyNode.FileRules.SelectNodes("//ns:FileRuleRef[starts-with(@RuleID, 'ID_ALLOW_')]", $NameSpace)

    # Append the Allow nodes that have an ID attribute that starts with ID_ALLOW_ to the array
    $NodesToRemove += $SiPolicyNode.FileRules.SelectNodes("//ns:Allow[starts-with(@ID, 'ID_ALLOW_')]", $NameSpace)

    # Loop through the nodes to remove
    foreach ($Node in $NodesToRemove) {
        # Get the parent node of the node to remove
        [System.Xml.XmlElement]$ParentNode = $Node.ParentNode
  
        # Check if the parent node has more than one child node, if it does then only remove the child node
        if ($ParentNode.ChildNodes.Count -gt 1) {
            # Remove the node from the parent node
            $ParentNode.RemoveChild($Node) | Out-Null
        }

        # If the parent node only has one child node then replace the parent node with an empty node
        else {
            # Create a new node with the same name and namespace as the parent node
            [System.Xml.XmlElement]$NewNode = $BlockRulesXML.CreateElement($ParentNode.Name, $ParentNode.NamespaceURI)
            # Replace the parent node with the new node
            $ParentNode.ParentNode.ReplaceChild($NewNode, $ParentNode) | Out-Null
    
            # Check if the new node has any sibling nodes, if not then replace its parent node with an empty node
            # We do this because the built-in PowerShell cmdlets would throw errors if empty <FileRulesRef /> exists inside <ProductSigners> node
            if ($null -eq $NewNode.PreviousSibling -and $null -eq $NewNode.NextSibling) {
                
                # Get the grandparent node of the new node
                [System.Xml.XmlElement]$GrandParentNode = $NewNode.ParentNode
                
                # Create a new node with the same name and namespace as the grandparent node
                [System.Xml.XmlElement]$NewGrandNode = $BlockRulesXML.CreateElement($GrandParentNode.Name, $GrandParentNode.NamespaceURI)
                
                # Replace the grandparent node with the new node
                $GrandParentNode.ParentNode.ReplaceChild($NewGrandNode, $GrandParentNode) | Out-Null
            }
        }
    }

    # Save the modified XML content to a file
    $BlockRulesXML.Save('.\Microsoft recommended block rules.xml') 

    # Remove the audit mode rule option
    Set-RuleOption -FilePath '.\Microsoft recommended block rules.xml' -Option 3 -Delete

    # Set HVCI to Strict
    Set-HVCIOptions -Strict -FilePath '.\Microsoft recommended block rules.xml'

    # Display the result
    Write-ColorfulText -Color MintGreen -InputText 'PolicyFile = Microsoft recommended block rules.xml'
}

# Export external facing functions only, prevent internal functions from getting exported
Export-ModuleMember -Function 'Get-BlockRulesMeta'

# SIG # Begin signature block
# MIILkgYJKoZIhvcNAQcCoIILgzCCC38CAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA+XzfRb1QgJXUr
# 1cEW4cbiznSHXYpdq2IVV8zib6QsoaCCB9AwggfMMIIFtKADAgECAhMeAAAABI80
# LDQz/68TAAAAAAAEMA0GCSqGSIb3DQEBDQUAME8xEzARBgoJkiaJk/IsZAEZFgNj
# b20xIjAgBgoJkiaJk/IsZAEZFhJIT1RDQUtFWC1DQS1Eb21haW4xFDASBgNVBAMT
# C0hPVENBS0VYLUNBMCAXDTIzMTIyNzExMjkyOVoYDzIyMDgxMTEyMTEyOTI5WjB5
# MQswCQYDVQQGEwJVSzEeMBwGA1UEAxMVSG90Q2FrZVggQ29kZSBTaWduaW5nMSMw
# IQYJKoZIhvcNAQkBFhRob3RjYWtleEBvdXRsb29rLmNvbTElMCMGCSqGSIb3DQEJ
# ARYWU3B5bmV0Z2lybEBvdXRsb29rLmNvbTCCAiIwDQYJKoZIhvcNAQEBBQADggIP
# ADCCAgoCggIBAKb1BJzTrpu1ERiwr7ivp0UuJ1GmNmmZ65eckLpGSF+2r22+7Tgm
# pEifj9NhPw0X60F9HhdSM+2XeuikmaNMvq8XRDUFoenv9P1ZU1wli5WTKHJ5ayDW
# k2NP22G9IPRnIpizkHkQnCwctx0AFJx1qvvd+EFlG6ihM0fKGG+DwMaFqsKCGh+M
# rb1bKKtY7UEnEVAsVi7KYGkkH+ukhyFUAdUbh/3ZjO0xWPYpkf/1ldvGes6pjK6P
# US2PHbe6ukiupqYYG3I5Ad0e20uQfZbz9vMSTiwslLhmsST0XAesEvi+SJYz2xAQ
# x2O4n/PxMRxZ3m5Q0WQxLTGFGjB2Bl+B+QPBzbpwb9JC77zgA8J2ncP2biEguSRJ
# e56Ezx6YpSoRv4d1jS3tpRL+ZFm8yv6We+hodE++0tLsfpUq42Guy3MrGQ2kTIRo
# 7TGLOLpayR8tYmnF0XEHaBiVl7u/Szr7kmOe/CfRG8IZl6UX+/66OqZeyJ12Q3m2
# fe7ZWnpWT5sVp2sJmiuGb3atFXBWKcwNumNuy4JecjQE+7NF8rfIv94NxbBV/WSM
# pKf6Yv9OgzkjY1nRdIS1FBHa88RR55+7Ikh4FIGPBTAibiCEJMc79+b8cdsQGOo4
# ymgbKjGeoRNjtegZ7XE/3TUywBBFMf8NfcjF8REs/HIl7u2RHwRaUTJdAgMBAAGj
# ggJzMIICbzA8BgkrBgEEAYI3FQcELzAtBiUrBgEEAYI3FQiG7sUghM++I4HxhQSF
# hqV1htyhDXuG5sF2wOlDAgFkAgEIMBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1Ud
# DwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBsGCSsGAQQBgjcVCgQOMAwwCgYIKwYB
# BQUHAwMwHQYDVR0OBBYEFOlnnQDHNUpYoPqECFP6JAqGDFM6MB8GA1UdIwQYMBaA
# FICT0Mhz5MfqMIi7Xax90DRKYJLSMIHUBgNVHR8EgcwwgckwgcaggcOggcCGgb1s
# ZGFwOi8vL0NOPUhPVENBS0VYLUNBLENOPUhvdENha2VYLENOPUNEUCxDTj1QdWJs
# aWMlMjBLZXklMjBTZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9u
# LERDPU5vbkV4aXN0ZW50RG9tYWluLERDPWNvbT9jZXJ0aWZpY2F0ZVJldm9jYXRp
# b25MaXN0P2Jhc2U/b2JqZWN0Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwgccG
# CCsGAQUFBwEBBIG6MIG3MIG0BggrBgEFBQcwAoaBp2xkYXA6Ly8vQ049SE9UQ0FL
# RVgtQ0EsQ049QUlBLENOPVB1YmxpYyUyMEtleSUyMFNlcnZpY2VzLENOPVNlcnZp
# Y2VzLENOPUNvbmZpZ3VyYXRpb24sREM9Tm9uRXhpc3RlbnREb21haW4sREM9Y29t
# P2NBQ2VydGlmaWNhdGU/YmFzZT9vYmplY3RDbGFzcz1jZXJ0aWZpY2F0aW9uQXV0
# aG9yaXR5MA0GCSqGSIb3DQEBDQUAA4ICAQA7JI76Ixy113wNjiJmJmPKfnn7brVI
# IyA3ZudXCheqWTYPyYnwzhCSzKJLejGNAsMlXwoYgXQBBmMiSI4Zv4UhTNc4Umqx
# pZSpqV+3FRFQHOG/X6NMHuFa2z7T2pdj+QJuH5TgPayKAJc+Kbg4C7edL6YoePRu
# HoEhoRffiabEP/yDtZWMa6WFqBsfgiLMlo7DfuhRJ0eRqvJ6+czOVU2bxvESMQVo
# bvFTNDlEcUzBM7QxbnsDyGpoJZTx6M3cUkEazuliPAw3IW1vJn8SR1jFBukKcjWn
# aau+/BE9w77GFz1RbIfH3hJ/CUA0wCavxWcbAHz1YoPTAz6EKjIc5PcHpDO+n8Fh
# t3ULwVjWPMoZzU589IXi+2Ol0IUWAdoQJr/Llhub3SNKZ3LlMUPNt+tXAs/vcUl0
# 7+Dp5FpUARE2gMYA/XxfU9T6Q3pX3/NRP/ojO9m0JrKv/KMc9sCGmV9sDygCOosU
# 5yGS4Ze/DJw6QR7xT9lMiWsfgL96Qcw4lfu1+5iLr0dnDFsGowGTKPGI0EvzK7H+
# DuFRg+Fyhn40dOUl8fVDqYHuZJRoWJxCsyobVkrX4rA6xUTswl7xYPYWz88WZDoY
# gI8AwuRkzJyUEA07IYtsbFCYrcUzIHME4uf8jsJhCmb0va1G2WrWuyasv3K/G8Nn
# f60MsDbDH1mLtzGCAxgwggMUAgEBMGYwTzETMBEGCgmSJomT8ixkARkWA2NvbTEi
# MCAGCgmSJomT8ixkARkWEkhPVENBS0VYLUNBLURvbWFpbjEUMBIGA1UEAxMLSE9U
# Q0FLRVgtQ0ECEx4AAAAEjzQsNDP/rxMAAAAAAAQwDQYJYIZIAWUDBAIBBQCggYQw
# GAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGC
# NwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQx
# IgQgwHqiUZ3SaZ3ZTpNWyFmK8hVrO8qbEeYX6BpSpU33MfwwDQYJKoZIhvcNAQEB
# BQAEggIAH7hx0LFU0ZQ6lCk8uINS3EHi7Oocp48S01uZVcvNWO/RZFuzGA2x5yVL
# kw4LokxrmmDVgOXfA8Kpf21l2nxtoFui9kQ9Oh5PZpwqH/iJztzKHeL5kHRwqRnV
# DqClXwYPNBXA/4zLuvEMhwwIFeyUzhlNy2/HLwtxup+QFe5JFRdftoTjpBSOxoBq
# ZVLdSIXWVQ8wZWQ2ruMpuMNDqeoB9aPk+2qD7JB5EXTLcHPvXoAoZ8OpxNuu0N3b
# 1UFXZNAMrY83QpTxVCh6byJxOjN21kCJgI8UwgNF+xHBGmVAVvJmHRgIeofGZWpv
# bn2Qv7c7oFLsmUvjVkQBZhT3TVllIjgK3jYIrZXbIAhi/l/tbyyQw9kFyBHJVskl
# DICp0e6z9GAlTZekUfLJ3STUZwov2S3hT2VXzhj5ppteHdQt9OdHJqF2mg3054w1
# yCMrENRjsEMcHx2yB8tWpXy9wyywmcP9jcsujldTgXnJQkgbxmCN3QUKU9FDTulk
# dZw46VwfuX6+0d+sf6e3VYgf13KT1zxNkXwBibO8cptRQlUgOD61QQjpXSWSo271
# FT+mOgiC2pZAVF3onwXRVxsBqDs4db2lrx9EEamzAYt3KLLATTi6uTe7GFyNjdqE
# mIb3x19IfZLbcNKgASaLe4oOcvMgD/Frsd90ynPTrWpSE07TLeg=
# SIG # End signature block
