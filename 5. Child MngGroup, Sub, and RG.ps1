
#Set Variables for Management Group Deployment#
Write-Host 'Enter desired Region'
$location = Read-Host
Write-Host = 'Enter desired Deployment Name'
$ChildDeployName = Read-Host
Write-Host = 'Enter Name of the Pseudo-Root Management Group'
$pseudoRootMGName = Read-Host
Write-Host = 'Enter filepath to the Child Management Group Bicep template'
$ChildBicepFile = Read-Host
Write-Host = 'Enter filepath to the Subcription Bicep template'
$subBicepFile = Read-Host
Write-Host = 'Enter file path to the Resource Group Bicep template'
$rgFile = Read-Host
#Deploy Management Groups#
New-AzTenantDeployment -Location $location -Name $ChildDeployName `
-TemplateFile $ChildBicepFile -pseudoRootMGName $pseudoRootMGName -ErrorAction Stop


#Set Variables for Subscription Deployment#
$getRootAndMngdeploy = Get-AzTenantDeployment -Name $ChildDeployName
$childId = $getRootAndMngdeploy.Outputs.foundationMGIdOut.Value | Select-Object -Index 0
$sub = "Sub"
$deploy = "Deploy"


#Get Billing Scope#
$azbillingacc = Get-AzBillingAccount
$billingprofilename = Get-AzBillingProfile -BillingAccountName $azbillingacc.Name
$billinginvoicename = Get-AzInvoiceSection -BillingAccountName $azbillingacc.Name `
-BillingProfileName $billingprofilename.Name
$azbillingp1 = "/providers/Microsoft.Billing/billingAccounts/"
$azprofilep1 = "/billingProfiles/"
$azinvoicep1 = "/invoiceSections/"
$azcompletebillingscope = $azbillingp1+$azbillingacc.Name+$azprofilep1+$billingprofilename.Name+$azinvoicep1+$billinginvoicename.Name


#Deploy Subscription#
$childIdAndDeploy = $childId+$deploy
$childIdAndSub = $childId+$sub
New-AzManagementGroupDeployment -Location $location -Name $childIdAndDeploy `
-ManagementGroupId $childId `
-TemplateFile $subBicepFile `
-billingScope $azcompletebillingscope `
-subscriptionName $childIdAndSub -workloadParam 'Production' -ErrorAction Stop
#attach the subscription to the management group#
$customSubId = Get-AzSubscription -SubscriptionName $childIdAndSub
New-AzManagementGroupSubscription -GroupName $childId -SubscriptionId $customSubId.Id -ErrorAction Stop


#Set Variables for Resource Group Deployment#
$rg = "Rg"
#Deploy Production Resource Group#
$childAndRgAndDeploy = $childId+$rg+$deploy
$childAndRg = $childId+$rg
Set-AzContext -SubscriptionName $childIdAndSub
New-AzDeployment -Location $location -Name $childAndRgAndDeploy `
-TemplateFile $rgFile `
-rgName $childAndRg -rgLocation $location -ErrorAction Stop

#Finish#
Write-Host 'Deployment Finished!'
