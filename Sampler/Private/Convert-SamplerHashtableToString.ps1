<#
.SYNOPSIS
Converts an Hashtable to its string representation, recursively.

.DESCRIPTION
Convert an Hashtable to a string representation.
For instance, this hashtable:
  @{a=1;b=2; c=3; d=@{dd='abcd'}}
Becomes:
  a=1; b=2; c=3; d={dd=abcd}

.PARAMETER Hashtable
Hashtable to convert to string.

.EXAMPLE
Convert-SamplerhashtableToString -Hashtable @{a=1;b=2; c=3; d=@{dd='abcd'}}

.NOTES
This command is not specific to Sampler projects, but is named that way
to avoid conflict with other modules.
#>
function Convert-SamplerHashtableToString
{
    param
    (
        [Parameter()]
        [System.Collections.Hashtable]
        $Hashtable
    )
    $values = @()
    foreach ($pair in $Hashtable.GetEnumerator())
    {
        if ($pair.Value -is [System.Array])
        {
            $str = "$($pair.Key)=($($pair.Value -join ","))"
        }
        elseif ($pair.Value -is [System.Collections.Hashtable])
        {
            $str = "$($pair.Key)={$(Convert-SamplerHashtableToString -Hashtable $pair.Value)}"
        }
        else
        {
            $str = "$($pair.Key)=$($pair.Value)"
        }
        $values += $str
    }

    [array]::Sort($values)
    return ($values -join "; ")
}
