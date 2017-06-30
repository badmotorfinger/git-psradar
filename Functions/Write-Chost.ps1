function Write-Chost($message = ""){

    if ( $message ){

        # predefined Color Array
        $colors = @("black","blue","cyan","darkblue","darkcyan","darkgray","darkgreen","darkmagenta","darkred","darkyellow","gray","green","magenta","red","white","yellow");    

        # Set CurrentColor to default Foreground Color
        $CurrentColor = $defaultFGColor

        # Split Messages
        $message = $message.split("#")

        # Iterate through splitted array
        foreach( $string in $message ){
            if ($string) {
                # If a string between #-Tags is equal to any predefined color, and is equal to the defaultcolor: set current color
                if ( $colors -contains $string.tolower()){
                    $CurrentColor = $string          
                }else{
                    # If string is a output message, than write string with current color (with no line break)
                    if ($CurrentColor -ne $null -and $CurrentColor -ne -1) {
                        write-host -nonewline -f $CurrentColor $string
                    } else {
                        write-host -nonewline $string
                    }
                }
            }
        }
    }
}