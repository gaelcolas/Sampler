Class class1 {
    [string]$Name = 'Class1'

    class1() {
        #default Constructor
    }

    [String] ToString()
    {
        return ( 'This calss is {0}' -f $this.Name)
    }
}