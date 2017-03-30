Class class1 {
    [string]$Name = 'Class1'

    [String] ToString()
    {
        return ( 'This calss is {0}' -f $this.Name)
    }
}