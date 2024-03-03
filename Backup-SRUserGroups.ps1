<#
sprawdź czy użytkownik istnieje
jesli tak
    pobierz grupy i zapisz w pliku
jeśli nie 
    loguj błąd
    
sprawdź czy użytkownik istnieje 
jeśli tak
    sprawdź czy jstnieje plik z grupami
    jeśli tak
        zaczytaj grupy z pliku
        dopuki są grupy
            sprawdź czy grupa istnieje
            jeśli tak
                sprawdź czy użytkownik należy do grupy
                jeśli nie
                    dodaj użytkownika do grupy
                jeśli tak
                    loguj komunikat
            jeśli nie 
                loguj błąd
    jeśli nie 
        loguj błąd
jeśli nie 
    loguj błąd#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory)]
        [String] $ADLogin,
        
        [Parameter(Mandatory)]
        [ValidateSet("Get", "Set")]
        [String] $Action
    )

    
    $userTest = $null
    $userGroups = $null
    $path = "C:\Temp"
    $file = Join-Path -Path $path -ChildPath "$ADLogin.txt"

    if($Action -like "Get"){
        try {
            $userTest = Get-ADUser -Identity $ADLogin -ErrorAction Stop
        }
        catch {
            Write-Verbose "Cannot find user: $ADLogin in AD."
        }

        if($userTest -ne $null){
            if(-not (Test-Path -Path $path)) {
                New-Item -Path $path -ItemType Directory | Out-Null
            }
            Get-ADPrincipalGroupMembership -Identity $ADLogin| Select-Object -ExpandProperty  Name | Add-Content -Path $file -Force
            if(Test-Path -Path $file) {
                Write-Host "File $ADLogin.txt was created in location: $path."
            }
        }
    }

    elseif ($Action -like "Set") {
        try {
            $userGroups =  Get-Content -Path $file -ErrorAction Stop
        }
        catch {
            Write-Verbose "Cannot find file: $file"
        }
        if($userGroups -ne $null) {
            foreach($group in $userGroups) {
                $testGroup = $null
                try {
                    $testGroup = Get-ADGroup -Identity $group
                }
                catch {
                    Write-Verbose "Cannot find group: $group"
                }
                if($testGroup -ne $null){
                    Write-Verbose "Add $ADLogin to group: $group"
                    Add-ADGroupMember -Identity $group -Members $ADLogin
                } 
            }
        }
    }
   