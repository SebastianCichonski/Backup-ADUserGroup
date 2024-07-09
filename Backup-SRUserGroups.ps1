<#
.SYNOPSIS
    Skrypt do tworzenia backupu uprawnie� u�ytkownik�w.

.DESCRIPTION
    Problem: Stworzy� kopi� zapasow� uprawnie� u�ytkownik�w (Wymaganie: uprawnienia s� nadawane dla grup a nie dla u�ytkownik�w.)

    Do skryptu przekazujemy login u�ytkownika, ponadto skrypt posiada parametr Action kt�ry mo�e mie� jedn� z dw�ch warto�ci: Get lub Set. 
    Wywo�any z warto�ci� Get skrypt pobiera wszystkie grupu do kt�rych nale�y dany u�ytkownik i zapisuje ich nazwy w pliku o nazwie identycznej 
    jak nazwa konta u�ytkownika. Wywo�any z warto�ci� Set, skrpt sprawdzi czy istnieje plik z kopi� grup je�li tak doda u�ytkownika do ka�dej grup z pliku.

.PARAMETER ADLogin
    Login u�ytkownika. Parametr wymagany.

.PARAMETER Action
    Rodzaj akcji kt�r� ma wykona� skrypt, mo�e przyj�� dwie warto�ci Get (backup uprawnie�) lub Set (przywr�cenie uprawnie�). Parametr wymagany.

.INPUTS
    None.

.OUTPUTS
    None.

.NOTES
    Version:        1.1
    Author:         Sebastian Cicho�ski
    Creation Date:  11.2023
    Projecturi:     https://gitlab.com/powershell1990849/backup-srusergroups
  
.EXAMPLE
  Backup-SRUserGroup.ps1 -ADLogin jan.kowalski -Action Get

  Utworzenie backupu uprawnie� w pliku: C:\Temp\userlogin.txt

.EXAMPLE
  Backup-SRUserGroup.ps1 -ADLogin jan.kowalski -Action Set

  Przywr�cenie uprawnie� z pliku : C:\Temp\userlogin.txt
#>

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
            Write-Verbose "Cannot find file: $file, use first 'Backup-SRUserGroups.ps1 -ADLogin userLogin -Action Get'"
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
   