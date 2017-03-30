Class class2 {
    [string]$Name = 'Class2'

    [String] ToString()
    {
        return ( 'This calss is {0}' -f $this.Name)
    }
}