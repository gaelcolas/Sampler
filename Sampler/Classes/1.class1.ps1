Class class1
{
    [string]$Name = 'Class1'

    class1()
    {
        #default Constructor
    }

    [String] ToString()
    {
        # Typo "calss" is intentional
        return ( 'This calss is {0}' -f $this.Name)
    }
}
