﻿$materialEntitySet = "Materials"
$materialEntityType = "Material"

function GetEntityNumber($entity) {
	if ($entity._EntityTypeID -eq "FILE") {
		$number = $entity._PartNumber
	}
	else {
		$number = $entity._Number
	}
	return $number
}

function GetErpMaterial($number) {
	Log -Begin
	if (-not $number) { 
		$erpMaterial = $false
		Add-Member -InputObject $erpMaterial -Name "_ErrorMessage" -Value "Number is empty!" -MemberType NoteProperty -Force
		return $erpMaterial
	}
	$number = $number.ToUpper()
	$erpMaterial = Get-ERPObject -EntitySet $materialEntitySet -Key @{ Number = $number }
	$erpMaterial = Edit-ResponseWithErrorMessage -Entity $erpMaterial
	
	Add-Member -InputObject $erpMaterial -Name "IsCreate" -Value $false -MemberType NoteProperty -Force
	Add-Member -InputObject $erpMaterial -Name "IsUpdate" -Value $true -MemberType NoteProperty -Force	
	Log -End
	return $erpMaterial
}

function NewErpMaterial {
	Log -Begin
	$erpMaterial = New-ERPObject -EntityType $materialEntityType

	#TODO: Property default values for material creation
	$erpMaterial.UnitOfMeasure = "PCS"
	$erpMaterial.Type = "Inventory"

	Add-Member -InputObject $erpMaterial -Name "IsCreate" -Value $true -MemberType NoteProperty -Force
	Add-Member -InputObject $erpMaterial -Name "IsUpdate" -Value $false -MemberType NoteProperty -Force
	Log -End
	return $erpMaterial
}

function CreateErpMaterial($erpMaterial) {
	Log -Begin
	#TODO: Numbering generation for material creation (only if needed)
	if ($null -eq $erpMaterial.Number -or $erpMaterial.Number -eq "") {
		$erpMaterial.Number = "*"
	}
	#TODO: Properties that need to be set on create
	$erpMaterial.ModifiedDate = [DateTime]::Now

	$erpMaterial.PSObject.Properties.Remove('IsCreate')
	$erpMaterial.PSObject.Properties.Remove('IsUpdate')

	$erpMaterial = TransformErpMaterial -erpMaterial $erpMaterial
	$erpMaterial = Add-ErpObject -EntitySet $materialEntitySet -Properties $erpMaterial
	$erpMaterial = Edit-ResponseWithErrorMessage -Entity $erpMaterial -WriteOperation
	Log -End
	return $erpMaterial
}

function UpdateErpMaterial($erpMaterial) {
	Log -Begin
	#TODO: Properties that need to be set on update
	$erpMaterial.ModifiedDate = [DateTime]::Now

	$erpMaterial = TransformErpMaterial -erpMaterial $erpMaterial
	$erpMaterial = Update-ERPObject -EntitySet $materialEntitySet -Key $erpMaterial._Keys -Properties $erpMaterial._Properties
	$erpMaterial = Edit-ResponseWithErrorMessage -Entity $erpMaterial -WriteOperation
	Log -End
	return $erpMaterial
}

function TransformErpMaterial($erpMaterial) {
	Log -Begin
	#TODO: Property transformations on create and update
	$erpMaterial.Number = $erpMaterial.Number.ToUpper()
	Log -End
	return $erpMaterial
}