Exports out an Azure SQL DB using gui prompts. You will select the Azure subscription, Azure Sql server, Azure Sql DB, Azure Storage Account and Azure Storage container to use. The storage account and container must already exist.
* Parameters for script
* resourceGroupName = Resource group name where the Azure SQL Server resource is. (OPTIONAL)
* sqlServerAdmin = Login name for the Sql Administration. Will pull the login name from the selected Sql Server if left out (OPTIONAL)
* sqlServerPassword = Password for the Sql Administration account. Will prompt you later if left out (OPTIONAL)
* statusBar = Displays a status bar with the export progress of the selected database (OPTIONAL)

Examples
.\Export-AzureSqlDB.ps1 -resourceGroupName 'eu-111-xm' -sqlServerAdmin <sqlAdminLogin> -sqlServerPassword <passwordHere> -statusBar

.\Export-AzureSqlDB.ps1 -resourceGroupName 'eu-111-xm' -sqlServerPassword <passwordHere> -statusBar

.\Export-AzureSqlDB.ps1 -resourceGroupName 'eu-111-xm'  -statusBar

.\Export-AzureSqlDB.ps1 -resourceGroupName 'eu-111-xm' 

.\Export-AzureSqlDB.ps1

Author: Jimmy Rudley 
