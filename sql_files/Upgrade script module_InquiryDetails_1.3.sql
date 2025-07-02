----- STEP 1 ----------
------ STEP 2 ----------    
-----End of Step 2 -------  

BEGIN TRY
	DECLARE @VersionCustom VARCHAR(100)
		,@Cmd NVARCHAR(max)
		,@ModuleKeyName VARCHAR(100) = 'Custom Data Model: Upgrade script module_InquiryDetails_1.3'
		,@SystemConfigKeyVersionBeforeUpgrade VARCHAR(150)
		,@UpgradeScriptVersion VARCHAR(10) = '1.3'
		,@SmartCareDataModelUpgradeId VARCHAR(20)
		,@ScriptModuleName VARCHAR(100) = 'CDM_InquiryDetails'

	IF OBJECT_ID('tempdb..#NewlyAddedIDTemp') IS NOT NULL
		DROP TABLE #NewlyAddedIDTemp

	CREATE TABLE #NewlyAddedIDTemp (NewPrimaryId INT)

	IF OBJECT_ID('SmartCareDataModelUpgrades') IS NOT NULL
	BEGIN
		SET @VersionCustom = (
				SELECT [value]
				FROM SystemConfigurationKeys
				WHERE [key] = @ScriptModuleName
				)
			 

		SELECT @SystemConfigKeyVersionBeforeUpgrade = isnull(@VersionCustom,'')
	
		SELECT @Cmd = N'INSERT INTO  SmartCareDataModelUpgrades(ModuleKeyName,UpgradeScriptVersion,
					SystemConfigKeyVersionBeforeUpgrade,StartDate,UpgradeStatus)
					OUTPUT INSERTED.SmartCareDataModelUpgradeId INTO #NewlyAddedIDTemp(NewPrimaryId)  
					select ''' + @ModuleKeyName + ''', ''' + @UpgradeScriptVersion + ''', ''' + @SystemConfigKeyVersionBeforeUpgrade + ''', getdate(), ''InProgress'''
			
		EXECUTE sp_executesql @Cmd;

		SELECT @SmartCareDataModelUpgradeId = NewPrimaryId
		FROM #NewlyAddedIDTemp
	END

------ STEP 3 ----------

IF OBJECT_ID('CustomInquiryElectronicEligibilityVerificationRequests') IS NOT NULL
BEGIN
  
	IF COL_LENGTH('CustomInquiryElectronicEligibilityVerificationRequests','InquiryId')IS NOT NULL
	 BEGIN
			IF  EXISTS (SELECT 1 FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[CustomInquiries_CustomInquiryElectronicEligibilityVerificationRequests_FK]') AND parent_object_id = OBJECT_ID(N'[dbo].[CustomInquiryElectronicEligibilityVerificationRequests]'))
			BEGIN
				ALTER TABLE CustomInquiryElectronicEligibilityVerificationRequests DROP CONSTRAINT CustomInquiries_CustomInquiryElectronicEligibilityVerificationRequests_FK

				PRINT '<<< DROPPED CONSTRAINT CustomInquiries_CustomInquiryElectronicEligibilityVerificationRequests_FK >>>'

				 PRINT 'STEP 3 COMPLETED'
			END
	  END
 
END  
 
------ END OF STEP 3 --- 
----- STEP 4 -------
-----END OF STEP 4------- 
	

IF NOT EXISTS (SELECT [key] FROM SystemConfigurationKeys WHERE [key] = 'CDM_InquiryDetails')
	BEGIN
		INSERT intO [dbo].[SystemConfigurationKeys]
				   (CreatedBy
				   ,CreateDate 
				   ,ModifiedBy
				   ,ModifiedDate
				   ,[Key]
				   ,[Value]
				   )
			 VALUES    
				   ('SHSDBA'
				   ,GETDATE()
				   ,'SHSDBA'
				   ,GETDATE()
				   ,'CDM_InquiryDetails'
				   ,'1.3'
				   )
				   
	SELECT @UpgradeScriptVersion = '1.3'

		SET @VersionCustom = (
				SELECT [value]
				FROM SystemConfigurationKeys
				WHERE [key] = 'CDM_InquiryDetails'
				)

		SELECT @SystemConfigKeyVersionBeforeUpgrade = ''

		SELECT @Cmd = N'INSERT intO  SmartCareDataModelUpgrades(ModuleKeyName,UpgradeScriptVersion,
					SystemConfigKeyVersionBeforeUpgrade,SystemConfigKeyVersionAfterUpgrade,StartDate,UpgradeStatus)
					OUTPUT INSERTED.SmartCareDataModelUpgradeId intO #NewlyAddedIDTemp(NewPrimaryId)  
					select ''' + @ModuleKeyName + ''', ''' + @UpgradeScriptVersion + ''', ''' + isnull(@SystemConfigKeyVersionBeforeUpgrade,'') + ''', ''1.3'', getdate(), ''Completed'''
				 
		EXECUTE sp_executesql @Cmd;

		SELECT @SmartCareDataModelUpgradeId = NewPrimaryId
		FROM #NewlyAddedIDTemp
	END 
 
	ELSE
	BEGIN
		SELECT @UpgradeScriptVersion = @VersionCustom
	END

	IF OBJECT_ID('SmartCareDataModelUpgrades') IS NOT NULL
	BEGIN
		SET @Cmd = ''
		
		SELECT @Cmd = 'UPDATE  SmartCareDataModelUpgrades  SET SystemConfigKeyVersionAfterUpgrade= ''' + isnull(@UpgradeScriptVersion,'1.3') + ''',EndDate= getdate(),UpgradeStatus= ''Completed'' WHERE  SmartCareDataModelUpgradeId =' + @SmartCareDataModelUpgradeId + ''
 
		EXECUTE sp_executesql @Cmd;

		PRint 'STEP 7 COMPLETED'
	END


END TRY

BEGIN CATCH
	DECLARE @Error varchar(5000)

	SET @Error = ERROR_MESSAGE()

	IF OBJECT_ID('SmartCareDataModelUpgrades') IS NOT NULL
	BEGIN
		SELECT @Cmd = N'UPDATE  SmartCareDataModelUpgrades  SET SystemConfigKeyVersionAfterUpgrade= ''' + @VersionCustom + ''',EndDate=getdate() ,UpgradeStatus= ''Error'', ErrorReason=''' + @Error + ''' WHERE  SmartCareDataModelUpgradeId =' + @SmartCareDataModelUpgradeId + ''

		EXECUTE sp_executesql @Cmd;

		RAISERROR (
				@Error
				,16
				,1
				);
	END
END CATCH

	------ STEP 5 ----------------
	-------END STEP 5------------- 
	------ STEP 6  ----------
	------ STEP 7 -----------