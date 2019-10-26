Class class2 {
    [string]$Name = 'Class2'

    class2()
    {
        #default constructor
    }
    
    [String] ToString()
    {
        return ( 'This calss is {0}' -f $this.Name)
    }
}