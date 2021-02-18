#=============================================================================#
# PowerShell script sample for coolOrange powerEvents                         #
# Restricts the state to release, if the validation for some properties fails.#
#                                                                             #
# Copyright (c) coolOrange s.r.l. - All rights reserved.                      #
#                                                                             #
# THIS SCRIPT/CODE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER   #
# EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES #
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT.  #
#=============================================================================#

$supportedPdfExtensions = @("idw", "dwg")
$requiresErpItemExtensions = @("iam", "ipn", "ipt")

function Verify-ErpForFileOrItem {
	param(
		$Entity # Can be a powerVault FILE or Vault object
	)	
	Log -Begin
	$entityNumber = GetEntityNumber -Entity $Entity		
	$erpMaterial = GetErpMaterial -Number $entityNumber
	try {
		Verify-VaultRestrictionWhenErpItemNotExists -ErpMaterial $erpMaterial -VaultEntity $Entity
		
		# ToDO: When ProAlpha is used then enable this line
		# Verify-VaultRestrictionWhenProAlphaStatusIsNotOk -ErpMaterial $erpMaterial
		
		Verify-VaultRestrictionWhenErpBomIsNotSynced -Entity $Entity
	}
	catch {
		$restrictMessage = "$($_)"
		Add-VaultRestriction -EntityName $entityNumber -Message $restrictMessage
	}
	Log -End
}

Register-VaultEvent -EventName UpdateFileStates_Restrictions -Action 'RestrictFileRelease'
function RestrictFileRelease($files) {
	Log -Begin
	try {
		$defs = $vault.LifeCycleService.GetAllLifeCycleDefinitions()
		$filesToCheck = $files | Where-Object { $_._Extension -in $requiresErpItemExtensions }
		foreach ($file in $filesToCheck) {	
			$def = $defs | Where-Object { $_.DispName -eq $file._NewLifeCycleDefinition }
			$state = $def.StateArray | Where-Object { $_.DispName -eq $file._NewState }
			if ($state.ReleasedState) {
				Verify-ErpForFileOrItem -Entity $file

				# ToDO: When SAP is used with change numbers then enable the lines below, check in the function if DIR or Material is needed
				# Verify-SapChangeNumbers -VaultEntity $Entity
			}
		}
	}
 catch {
		#Show-Inspector
		Log -Message $_.Exception.Message -MessageBox -LogLevel "ERROR"
	}
	Log -End
}

Register-VaultEvent -EventName UpdateItemStates_Restrictions -Action 'RestrictItemRelease'
function RestrictItemRelease($items) {
	Log -Begin
	try {
		$defs = $vault.LifeCycleService.GetAllLifeCycleDefinitions()
		foreach ($item in $items) {
			$allItemAssociations = Get-VaultItemAssociations -Number $item._Number
			$itemIncludesFilesToCheck = $allItemAssociations | Where-Object { $_._Extension -in $script:requiresErpItemExtensions }
			$def = $defs | Where-Object { $_.DispName -eq $item._NewLifeCycleDefinition }
			$state = $def.StateArray | Where-Object { $_.DispName -eq $item._NewState }
			if ($itemIncludesFilesToCheck -and $state.ReleasedState) {
				Verify-ErpForFileOrItem -Entity $item		
			}
		}
		catch {
			Log -Message $_.Exception.Message -MessageBox -LogLevel "ERROR"
		}
		Log -End
	}
}

Register-VaultEvent -EventName UpdateFileStates_Post -Action 'AddPdfJob'
function AddPdfJob($files, $successful) {
	Log -Begin
	try {
		if (-not $successful) { return }
		$releasedFiles = @($files | Where-Object { $supportedPdfExtensions -contains $_._Extension -and $_._ReleasedRevision -eq $true })
		foreach ($file in $releasedFiles) {
			$material = GetErpMaterial -Number $file._PartNumber
			if ($false -ne $material -and $material) {
				$jobType = "ErpService.Create.PDF"
				Log -Message "Adding job '$jobType' for file '$($file._Name)' to queue."
				Add-VaultJob -Name $jobType -Parameters @{ "EntityId" = $file.Id; "EntityClassId" = "FILE" } -Description "Create PDF for file '$($file._Name)' and upload to ERP system"
			}
		}
	}
	catch {
		Log -Message $_.Exception.Message -MessageBox
	}
	Log -End
}