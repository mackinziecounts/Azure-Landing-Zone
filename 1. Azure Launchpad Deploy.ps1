Connect-AzAccount
#Set Variables for Management Group Deployment#
Write-Host 'Enter desired Region'
$location = Read-Host
Write-Host = 'Enter desired Deployment Name'
$rootAndChildrenDeployName = Read-Host
Write-Host = 'Enter filepath to the Root and Management Groups Bicep template'
$rootAndChildrenBicepFile = Read-Host
Write-Host = 'Enter filepath to the Subcription Bicep template'
$subBicepFile = Read-Host
Write-Host = 'Enter file path to the Resource Group Bicep template'
$rgFile = Read-Host
$pseudoRootMGNamevar = $rootAndChildrenDeployName
#Deploy Management Groups#
New-AzTenantDeployment -Location $location -Name $rootAndChildrenDeployName `
-TemplateFile $rootAndChildrenBicepFile -pseudoRootMGName $pseudoRootMGNamevar -ErrorAction Stop


#Set Variables for Subscription Deployment#
$getRootAndMngdeploy = Get-AzTenantDeployment -Name $rootAndChildrenDeployName
$childId1 = $getRootAndMngdeploy.Outputs.foundationMGIdOut.Value | Select-Object -Index 0
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
$childId1AndDeploy = $childId1+$deploy
$childId1AndSub = $childId1+$sub
New-AzManagementGroupDeployment -Location $location -Name $childId1AndDeploy `
-ManagementGroupId $childId1 `
-TemplateFile $subBicepFile `
-billingScope $azcompletebillingscope `
-subscriptionName $childId1AndSub -workloadParam 'Production' -ErrorAction Stop
#attach the subscription to the management group#
$customSubId = Get-AzSubscription -SubscriptionName $childId1AndSub
New-AzManagementGroupSubscription -GroupName $childId1 -SubscriptionId $customSubId.Id -ErrorAction Stop


#Set Variables for Resource Group Deployment#
$rg = "Rg"
#Deploy Production Resource Group#
$child1AndRgAndDeploy = $childId1+$rg+$deploy
$child1AndRg = $childId1+$rg
Set-AzContext -SubscriptionName $childId1AndSub
New-AzDeployment -Location $location -Name $child1AndRgAndDeploy `
-TemplateFile $rgFile `
-rgName $child1AndRg -rgLocation $location -ErrorAction Stop

#Finish#
Write-Host 'Azure Launchpad Deployment Finished!'
