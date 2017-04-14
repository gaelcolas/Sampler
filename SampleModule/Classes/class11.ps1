Class class11 : class1 {
    [string]$Name = 'Class11'

    class11 ()
    {

    }
    
    [String] ToString()
    {
        return ( 'This calss is {0}:{1}' -f $this.Name,'class1')
    }
}