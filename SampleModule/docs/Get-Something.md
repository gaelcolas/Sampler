---
external help file: SampleModule-help.xml
online version: 
schema: 2.0.0
---

# Get-Something

## SYNOPSIS
Sample Function to return input string.

## SYNTAX

```
Get-Something [-Data] <String> [-WhatIf] [-Confirm]
```

## DESCRIPTION
This function is only a sample Advanced function that returns the Data given via parameter Data.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------
```
Get-Something -Data 'Get me this text'
```

## PARAMETERS

### -Data
The Data parameter is the data that will be returned without transformation.

```yaml
Type: String
Parameter Sets: (All)
Aliases: 

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

