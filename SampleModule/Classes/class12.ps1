Class class12 : class1 {
    [string]$Name = 'Class12'

    class12 ()
    {
        
    }

    [String] ToString()
    {
        return ( 'This calss is {0}:{1}' -f $this.Name,'class1')
    }
}