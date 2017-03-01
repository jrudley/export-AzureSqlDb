 <#
Exports out an Azure SQL DB using gui prompts. You will select the Azure subscription, Azure Sql server, Azure Sql DB, Azure Storage Account and Azure Storage container to use. The storage account and container must already exist.
•Parameters for script
•resourceGroupName = Resource group name where the Azure SQL Server resource is. (OPTIONAL)
•sqlServerAdmin = Login name for the Sql Administration. Will pull the login name from the selected Sql Server if left out (OPTIONAL)
•sqlServerPassword = Password for the Sql Administration account. Will prompt you later if left out (OPTIONAL)
•statusBar = Displays a status bar with the export progress of the selected database (OPTIONAL)

Examples
.\Export-AzureSqlDB.ps1 -resourceGroupName 'eu-111-xm' -sqlServerAdmin <sqlAdminLogin> -sqlServerPassword <passwordHere> -statusBar

.\Export-AzureSqlDB.ps1 -resourceGroupName 'eu-111-xm' -sqlServerPassword <passwordHere> -statusBar

.\Export-AzureSqlDB.ps1 -resourceGroupName 'eu-111-xm'  -statusBar

.\Export-AzureSqlDB.ps1 -resourceGroupName 'eu-111-xm' 

.\Export-AzureSqlDB.ps1

Author: Jimmy Rudley

#>

param (
    [Parameter(Position=0)]
    [ValidateNotNullOrEmpty()]
    [string]$resourceGroupName,

    [Parameter(Position=1)]
    [ValidateNotNullOrEmpty()]
    [string]$sqlServerAdmin,

　
    [Parameter(Position=2)]
    [ValidateNotNullOrEmpty()]
    [string]$sqlServerPassword,
   
    [Parameter(Position=3)]
    [switch]$statusBar 
)

try 
{
    $AzureSubscriptionId =     (Get-AzureRmSubscription | Out-GridView -Title 'Select an Azure Subscription' -OutputMode Single)
    Set-AzureRmContext -SubscriptionID $AzureSubscriptionId
}
catch 
{
    Login-AzureRmAccount
    $AzureSubscriptionId =     (Get-AzureRmSubscription | Out-GridView -Title 'Select an Azure Subscription' -OutputMode Single)
    Set-AzureRmContext -SubscriptionID $AzureSubscriptionId
}

try
{
    if(!($PSBoundParameters.ContainsKey('resourceGroupName')))
    {
    $resourceGroupName = (Get-AzureRmResourceGroup | Out-GridView -Title 'Select a Resource Group' -OutputMode Single).ResourceGroupName
    }
   
    $sqlServer = Get-AzureRmSqlserver -ResourceGroupName $resourceGroupName | Out-GridView  -Title 'Select your Azure SQL Server'  -OutputMode Single

    $sqlDB = (Get-AzureRmSqlDatabase -ResourceGroupName $resourceGroupName -ServerName $sqlServer.ServerName | where {$_.DatabaseName -ne 'master'} | Out-GridView  -Title 'Select a DB to export' -OutputMode Single).DatabaseName
   
    if(!($PSBoundParameters.ContainsKey('sqlServerAdmin')))
    {
    $sqlServerAdmin = $sqlserver.SqlAdministratorLogin
    }

    if(!($PSBoundParameters.ContainsKey('sqlServerPassword')))
    {
    $securePassword = Read-Host "Enter in the password for $sqlServerAdmin" -AsSecureString
    }
    else
    {
    $securePassword = ConvertTo-SecureString -String $sqlServerPassword -AsPlainText -Force
    }
    
    #$sqlServerAdmin = $sqlserver.SqlAdministratorLogin
    $creds = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $sqlServerAdmin, $securePassword

    # Generate a unique filename for the BACPAC
    $bacpacFilename =  $sqlDB + (Get-Date).ToString("yyyyMMddHHmm") + ".bacpac"

    # Storage account info for the BACPAC
    $storageAcct = Get-AzureRmStorageAccount | Out-GridView -Title 'Select a Storage Account' -OutputMode Single
    $key1 = (Get-AzureRmStorageAccountKey -ResourceGroupName $storageAcct.ResourceGroupName -name $storageAcct.StorageAccountName)[0].value
    $storageContext = New-AzureStorageContext -StorageAccountName $storageAcct.StorageAccountName -StorageAccountKey $key1
    $storageContainer = Get-AzureStorageContainer -Context $storageContext | select Name | Out-GridView  -Title 'Select a Container..' -OutputMode Single

    $BaseStorageUri = "$($storageAcct.PrimaryEndpoints.Blob)$($storageContainer.Name)/"

    $BacpacUri = $BaseStorageUri + $bacpacFilename

    $exportRequest = New-AzureRmSqlDatabaseExport -ResourceGroupName $resourceGroupName -ServerName $sqlServer.ServerName `
       -DatabaseName $sqlDB -StorageKeytype 'StorageAccessKey' -StorageKey $key1  -StorageUri $BacpacUri `
       -AdministratorLogin $creds.UserName -AdministratorLoginPassword $creds.Password

    if ($PSBoundParameters.ContainsKey('statusBar'))
    {
        [int]$expStatusctr = 0
        $expStatus = Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $exportRequest.OperationStatusLink

        while ($expStatus.Status -ne 'Succeeded')
        {
        Write-Progress -Activity "Exporting Database $($sqlDB.DatabaseName)" -PercentComplete (($expStatusctr / 100) * 100)

        start-sleep -Milliseconds 200
        $expStatus = Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $exportRequest.OperationStatusLink
            if ($expStatus.StatusMessage)
            {
            
            $expStatus = $expStatus.StatusMessage.Split('=') 
            $expStatusctr=$expStatus[1].Trim('%')
            
            }
        }
    Write-Host "Export complete! $BacpacUri" -ForegroundColor Green
    }
    else
    {
    Write-Host "Exporting to $BacpacUri. It should be done exporting soon..."
    }
}
catch
{
$Error[0]
}

 
