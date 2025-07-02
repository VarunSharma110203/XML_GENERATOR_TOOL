/*
Date -2025-05-29
Authors:Nithya S
What: Added SmartCare configuration and payers to the tables
Why: DevOps_538051

*/
DECLARE @UserCode VARCHAR(50) = 'Kansas Mental, 130226'
DECLARE @CurrDateTime DATETIME = GETDATE()
DECLARE @WebServiceURL VARCHAR(max) = 'https://datasrv.smartcarenet.com/SCDataServicesProd/SCEligibility.asmx'
DECLARE @WebServiceUserName VARCHAR(50) = 'Kansas' -- gateway name from scdata service
DECLARE @WebServicePassword VARCHAR(50) = 'Kansas@164!' -- authsecret from scdata service script
DECLARE @ProviderName VARCHAR(50) = 'KansasREST' -- gateway name from scdata service script 
DECLARE @ElectronicEligibilityVerificationConfigurationId INT;

SET @ElectronicEligibilityVerificationConfigurationId = 0

IF EXISTS (
		SELECT *
		FROM ElectronicEligibilityVerificationConfigurations
		WHERE ProviderName = 'migateway,'
			AND ElectronicEligibilityVerificationConfigurationId = 7
		)
BEGIN
	UPDATE cfg
	SET WebServiceURL = @WebServiceURL
		,WebServiceUserName = @WebServiceUserName
		,WebServicePassword = @WebServicePassword
		,ProviderName = @ProviderName
		,UpdateEligibilityStoredProcedureName = 'ssp_SCUpdateElectronicEligibilityData'
		,UpdateClientCoveragePlanProcedureName = 'ssp_SCUpdateElectronicEligibilityClientCoveragePlanNew'
		,CreateElectronicEligibilityVerificationBatchIdStoredProcedureName = 'ssp_SCCreateElectronicEligibilityVerificationBatchId'
		,QueryElectronicEligibilityBatchVerificationDataStoredProcedureName = 'ssp_SCQueryElectronicEligibilityBatchVerificationData'
	FROM dbo.ElectronicEligibilityVerificationConfigurations AS cfg
	WHERE ElectronicEligibilityVerificationConfigurationId = 7
		AND (
			cfg.RecordDeleted IS NULL
			OR cfg.RecordDeleted = 'N'
			)

	SET @ElectronicEligibilityVerificationConfigurationId = 7
END;
ELSE IF NOT EXISTS (
		SELECT *
		FROM ElectronicEligibilityVerificationConfigurations
		WHERE ProviderName = @ProviderName
		)
BEGIN
	INSERT INTO ElectronicEligibilityVerificationConfigurations (
		CreatedBy
		,CreatedDate
		,ModifiedBy
		,ModifiedDate
		,RecordDeleted
		,DeletedDate
		,DeletedBy
		,AllowableHoursSinceLastVerified
		,RequestTimeoutSeconds
		,DefaultServiceStartDateDaysBackFromCurrentDate
		,DefaultServiceEndDateDaysForwardFromCurrentDate
		,WebServiceURL
		,WebServiceUserName
		,WebServicePassword
		,ProviderName
		,UpdateEligibilityStoredProcedureName
		,UpdateClientCoveragePlanProcedureName
		,CreateElectronicEligibilityVerificationBatchIdStoredProcedureName
		,QueryElectronicEligibilityBatchVerificationDataStoredProcedureName
		)
	VALUES (
		CURRENT_USER
		,GETDATE()
		,CURRENT_USER
		,GETDATE()
		,NULL
		,NULL
		,NULL
		,24
		,30
		,0
		,0
		,@WebServiceURL
		,@WebServiceUserName
		,@WebServicePassword
		,@ProviderName
		,'ssp_SCUpdateElectronicEligibilityData'
		,'ssp_SCUpdateElectronicEligibilityClientCoveragePlanNew'
		,'ssp_SCCreateElectronicEligibilityVerificationBatchId'
		,'ssp_SCQueryElectronicEligibilityBatchVerificationData'
		)

	SET @ElectronicEligibilityVerificationConfigurationId = SCOPE_IDENTITY()
END

UPDATE cfg
SET Value = 'N'
	,ModifiedBy = @UserCode
	,ModifiedDate = @CurrDateTime --was N
	--SELECT	Value
FROM dbo.SystemConfigurationKeys AS cfg
WHERE (
		[Key] = 'SENDMINIMALINFORMATION' --see ssp_SCExecuteElectronicEligibilityVerification - used to clear the first, last and SSN fields if a date of birth and insured id are supplied
		--OR
		--[Key] = 'CLEARMEDICAID'		--see ssp_SCExecuteElectronicEligibilityVerification - used to Remove Medicaid from 270 Request if the medicaid id is invalid
		);

----------------------------------------------------
--Payers
DECLARE @Payers TABLE (
	ElectronicPayerId VARCHAR(max)
	,ElectronicPayerName VARCHAR(max)
	,ResponseXSL XML
	)
DECLARE @MCDXSL NVARCHAR(MAX) = 
	'<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"><xsl:output omit-xml-declaration="yes" /><xsl:template match="/eligibilityresponse|responseXml"><html><body><xsl:choose><xsl:when test="count(SummaryCoverages/SummaryCoverage) = 0"><h2><xsl:value-of select="infosource/payername" /> Eligibility: NON-BILLABLE</h2></xsl:when><xsl:when test="count(SummaryCoverages/SummaryCoverage) = 1 and not(SummaryCoverages/SummaryCoverage/CoverageStartDate[1]) and not(SummaryCoverages/SummaryCoverage/CoverageEndDate[1])"><h2><xsl:value-of select="infosource/payername" /> Eligibility:  <xsl:value-of select="SummaryCoverages/SummaryCoverage/VerifiedResponseType[1]" /></h2></xsl:when><xsl:otherwise><h2><xsl:value-of select="infosource/payername" /> Eligibility</h2><xsl:apply-templates select="SummaryCoverages" /><br /></xsl:otherwise></xsl:choose><xsl:apply-templates select="infosource/rejection" /><br /><h2>Subscriber</h2><xsl:apply-templates select="subscriber/rejection" /><h3>Patient</h3><table border="0"><tr style="color: white" bgcolor="#2c689e"><th>First Name</th><th>Last Name</th><th>Patient Address</th><th>Patient City</th><th>Patient State</th><th>Patient Zip</th></tr><xsl:apply-templates select="subscriber/patientname" /></table><h3>Detail Benefits</h3><table border="0"><tr style="color: white" bgcolor="#2c689e"><th>Info</th><th>Coverage Level</th><th>Service Type</th><th>Insurance Type</th><th>Benefit Entity Name</th><th>Plan Coverage Description</th><th>Group Policy Num</th><th>Start Service Date</th><th>End Service Date</th><th>Commercial Insurance Name</th><th>Message 1</th><th>Message 2</th><th>Message 3</th></tr><xsl:apply-templates select="subscriber/benefit" /></table><h3>Additional Subscriber Information</h3><table border="0"><xsl:apply-templates select="subscriber" /></table><br /><table border="0"><tr style="color: white" bgcolor="#2c689e"><th>Sub Supplemental Id</th><th>Group Policy #</th></tr><xsl:apply-templates select="subscriber/subscriberaddinfo" /></table><h2>Information Source</h2><table border="0"><xsl:apply-templates select="infosource" /></table><h2>Information Receiver</h2><table border="0"><xsl:apply-templates select="inforeceiver" /></table></body></html></xsl:template><xsl:template match="subscriber/rejection"><table border="0"><tr bgcolor="#FFFF00"><td>Eligibility check failed:</td><td><xsl:value-of select="current()/rejectreason" /></td></tr><tr bgcolor="#FFFF00"><td>Action to take:</td><td><xsl:value-of select="current()/followupaction" /></td></tr></table></xsl:template><xsl:template match="infosource/rejection"><table border="0"><tr bgcolor="#FFFF00"><td>Eligibility check failed:</td><td><xsl:value-of select="current()/rejectreason" /></td></tr><tr bgcolor="#FFFF00"><td>Action to take:</td><td><xsl:value-of select="current()/followupaction" /></td></tr></table></xsl:template><xsl:template match="infosource"><tr><td>Payer Name:</td><td><xsl:value-of select="current()/payername" /></td></tr><tr><td>Payer Id:</td><td><xsl:value-of select="current()/payerid" /></td></tr></xsl:template><xsl:template match="inforeceiver"><tr><td>Provider Id:</td><td><xsl:value-of select="current()/providerid" /></td></tr><tr><td>Provider Secondary Id:</td><td><xsl:value-of select="current()/providersecondaryid" /></td></tr></xsl:template><xsl:template match="subscriber/benefit"><tr><td><xsl:value-of select="current()/info" /></td><td><xsl:value-of select="current()/coveragelevel" /></td><td><xsl:value-of select="current()/servicetype" /></td><td><xsl:value-of select="current()/insurancetype" /></td><td><xsl:value-of select="current()/benefitentity/name" /></td><td><xsl:value-of select="current()/plancoveragedescription" /></td><td><xsl:value-of select="current()/subscriberaddinfo/grouppolicynum" /></td><td><xsl:choose><xsl:when test="contains(current()/date-of-service,''-'')"><xsl:value-of select="substring-before(current()/date-of-service,''-'')" /></xsl:when><xsl:otherwise><xsl:value-of select="current()/date-of-service" /></xsl:otherwise></xsl:choose></td><td><xsl:choose><xsl:when test="contains(current()/date-of-service,''-'')"><xsl:value-of select="substring-after(current()/date-of-service,''-'')" /></xsl:when><xsl:otherwise><xsl:value-of select="current()/date-of-service" /></xsl:otherwise></xsl:choose></td><td><xsl:value-of select="current()/subscriberaddinfo/description" /></td><td><xsl:value-of select="current()/message[1]" /></td><td><xsl:value-of select="current()/message[2]" /></td><td><xsl:value-of select="current()/message[3]" /></td></tr></xsl:template><xsl:template match="subscriber/subscriberaddinfo"><tr><td><xsl:value-of select="current()/subsupplementalid" /></td><td><xsl:value-of select="current()/grouppolicynum" /></td></tr></xsl:template><xsl:template match="subscriber/patientname"><tr><td><xsl:value-of select="current()/first" /></td><td><xsl:value-of select="current()/last" /></td><td><xsl:value-of select="current()/patientaddress" /></td><td><xsl:value-of select="current()/patientcity" /></td><td><xsl:value-of select="current()/patientstate" /></td><td><xsl:value-of select="current()/patientzip" /></td></tr></xsl:template><xsl:template match="subscriber"><tr><td>Gender:</td><td><xsl:value-of select="current()/sex" /></td></tr><tr><td>DOB:</td><td><xsl:value-of select="current()/date-of-birth" /></td></tr><tr><td>Patient Id:</td><td><xsl:value-of select="current()/patientid" /></td></tr><tr><td>Information Contact:</td><td><xsl:value-of select="current()/informationcontact" /></td></tr></xsl:template><xsl:template match="SummaryCoverages"><table border="0"><tr style="color: white" bgcolor="#2c689e"><th>Eligibility</th><th>Coverage Start Date</th><th>Coverage End Date</th></tr><xsl:for-each select="current()/SummaryCoverage"><xsl:sort select="CoverageStartDate" /><tr><td><xsl:value-of select="VerifiedResponseType" /></td><td><xsl:value-of select="CoverageStartDate" /></td><td><xsl:value-of select="CoverageEndDate" /></td></tr></xsl:for-each></table></xsl:template></xsl:stylesheet>'
	,@CommercialXSL XML = 
	'<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"> <xsl:output omit-xml-declaration="yes" /> <xsl:template match="/eligibilityresponse|responseXml"> <html> <body> <script> $(document).ready(function () { $("table.fixedHeader").floatThead({ useAbsolutePositioning: false, scrollContainer: function($table){ return $table.closest(''.wrapper''); } }); }); </script> <xsl:choose> <xsl:when test="count(SummaryCoverages/SummaryCoverage) = 0"> <h2> <xsl:value-of select="infosource/payername" /> Eligibility: NON-BILLABLE</h2> </xsl:when> <xsl:when test="count(SummaryCoverages/SummaryCoverage) = 1 and not(SummaryCoverages/SummaryCoverage/CoverageStartDate[1]) and not(SummaryCoverages/SummaryCoverage/CoverageEndDate[1])"> <h2> <xsl:value-of select="infosource/payername" /> Eligibility:  <xsl:value-of select="SummaryCoverages/SummaryCoverage/VerifiedResponseType[1]" /></h2> </xsl:when> <xsl:otherwise> <h2> <xsl:value-of select="infosource/payername" /> Eligibility</h2> <xsl:apply-templates select="SummaryCoverages" /> <br /> </xsl:otherwise> </xsl:choose> <br /> <h2>Subscriber</h2> <xsl:apply-templates select="subscriber/rejection" /> <xsl:apply-templates select="infosource/rejection" /> <h3>Patient</h3> <table border="0"> <tr style="color: white" bgcolor="#2c689e"> <th>First Name</th> <th>Last Name</th> <th>Patient Address</th> <th>Patient City</th> <th>Patient State</th> <th>Patient Zip</th> </tr> <xsl:apply-templates select="subscriber/patientname" /> </table> <h3>Dependent</h3> <table border="0"> <tr style="color: white" bgcolor="#2c689e"> <th>First Name</th> <th>Last Name</th> <th>Dependent Address</th> <th>Dependent City</th> <th>Dependent State</th> <th>Dependent Zip</th> <th>Gender</th> <th>DOB</th> </tr> <xsl:apply-templates select="subscriber/dependentname" /> </table> <h3>Detail Benefits</h3> <table border="1" class="fixedHeader"> <thead> <tr style="color: white" bgcolor="#2c689e"> <th>Info</th> <th>Coverage Level</th> <th>Service Type</th> <th>Insurance Type</th> <th>Benefit Entity Name</th> <th>Plan Coverage Description</th> <th>Group Policy Num</th> <th>Start Service Date</th> <th>End Service Date</th> <th>Commercial Insurance Name</th> <th>Network</th> <th>Co-insurance</th> <th>Co-Pay amount</th> <th>Deductible</th> <th>Out of Pocket</th> <th>Message 1</th> <th>Message 2</th> <th>Message 3</th> </tr> </thead> <xsl:apply-templates select="subscriber/benefit" /> </table> <h3>Additional Subscriber Information</h3> <table border="0"> <xsl:apply-templates select="subscriber" /> </table> <br /> <table border="0"> <tr style="color: white" bgcolor="#2c689e"> <th>Sub Supplemental Id</th> <th>Group Policy #</th> </tr> <xsl:apply-templates select="subscriber/subscriberaddinfo" /> </table> <h2>Information Source</h2> <table border="0"> <xsl:apply-templates select="infosource" /> </table> <h2>Information Receiver</h2> <table border="0"> <xsl:apply-templates select="inforeceiver" /> </table> </body> </html> </xsl:template> <xsl:template match="subscriber/rejection"> <table border="0"> <tr bgcolor="#FFFF00"> <td>Eligibility check failed:</td> <td> <xsl:value-of select="current()/rejectreason" /> </td> </tr> <tr bgcolor="#FFFF00"> <td>Action to take:</td> <td> <xsl:value-of select="current()/followupaction" /> </td> </tr> </table> </xsl:template> <xsl:template match="infosource/rejection"> <table border="0"> <tr bgcolor="#FFFF00"> <td>Eligibility check failed:</td> <td> <xsl:value-of select="current()/rejectreason" /> </td> </tr> <tr bgcolor="#FFFF00"> <td>Action to take:</td> <td> <xsl:value-of select="current()/followupaction" /> </td> </tr> </table> </xsl:template> <xsl:template match="infosource"> <tr> <td>Payer Name:</td> <td> <xsl:value-of select="current()/payername" /> </td> </tr> <tr> <td>Payer Id:</td> <td> <xsl:value-of select="current()/payerid" /> </td> </tr> </xsl:template> <xsl:template match="inforeceiver"> <tr> <td>Provider Id:</td> <td> <xsl:value-of select="current()/providerid" /> </td> </tr> <tr> <td>Provider Secondary Id:</td> <td> <xsl:value-of select="current()/providersecondaryid" /> </td> </tr> </xsl:template> <xsl:template match="subscriber/benefit"> <xsl:if test="current()/servicetypecode !=''35''"> <tr> <td> <xsl:value-of select="current()/info" /> </td> <td> <xsl:value-of select="current()/coveragelevel" /> </td> <td> <xsl:value-of select="current()/servicetype" /> </td> <td> <xsl:value-of select="current()/insurancetype" /> </td> <td> <xsl:value-of select="current()/benefitentity/name" /> </td> <td> <xsl:value-of select="current()/plancoveragedescription" /> </td> <td> <xsl:value-of select="current()/subscriberaddinfo/grouppolicynum" /> </td> <td> <xsl:choose> <xsl:when test="contains(current()/date-of-service,''-'')"> <xsl:value-of select="substring-before(current()/date-of-service,''-'')" /> </xsl:when> <xsl:otherwise> <xsl:value-of select="current()/date-of-service[@id=''193'']" /> </xsl:otherwise> </xsl:choose> </td> <td> <xsl:choose> <xsl:when test="contains(current()/date-of-service,''-'')"> <xsl:value-of select="substring-after(current()/date-of-service,''-'')" /> </xsl:when> <xsl:otherwise> <xsl:value-of select="current()/date-of-service[@id=''194'']" /> </xsl:otherwise> </xsl:choose> </td> <td> <xsl:value-of select="current()/subscriberaddinfo/description" /> </td> <td> <xsl:if test="current()/inplannetwork"> <xsl:choose> <xsl:when test="current()/inplannetwork=''Yes''"> <xsl:text>In</xsl:text> </xsl:when> <xsl:when test="current()/inplannetwork=''No''"> <xsl:text>Out</xsl:text> </xsl:when> <xsl:otherwise> <xsl:text>Unknown</xsl:text> </xsl:otherwise> </xsl:choose> </xsl:if> <!--<xsl:value-of select="current()/inplannetwork"/>--> </td> <td> <xsl:if test="current()/coinsurance"> <xsl:value-of select="current()/coinsurance * 100 " />%</xsl:if> </td> <td> <xsl:if test="current()/copayamount"> $<xsl:value-of select="current()/copayamount" /></xsl:if> </td> <td> <xsl:if test="current()/deductibleamount"> $<xsl:value-of select="current()/deductibleamount" /></xsl:if> </td> <td> <xsl:if test="current()/outofpocketamount"> $<xsl:value-of select="current()/outofpocketamount" /></xsl:if> </td> <td> <xsl:value-of select="current()/message[1]" /> </td> <td> <xsl:value-of select="current()/message[2]" /> </td> <td> <xsl:value-of select="current()/message[3]" /> </td> </tr> </xsl:if> </xsl:template> <xsl:template match="subscriber/subscriberaddinfo"> <tr> <td> <xsl:value-of select="current()/subsupplementalid" /> </td> <td> <xsl:value-of select="current()/grouppolicynum" /> </td> </tr> </xsl:template> <xsl:template match="subscriber/patientname"> <tr> <td> <xsl:value-of select="current()/first" /> </td> <td> <xsl:value-of select="current()/last" /> </td> <td> <xsl:value-of select="current()/patientaddress" /> </td> <td> <xsl:value-of select="current()/patientcity" /> </td> <td> <xsl:value-of select="current()/patientstate" /> </td> <td> <xsl:value-of select="current()/patientzip" /> </td> </tr> </xsl:template> <xsl:template match="subscriber/dependentname"> <tr> <td> <xsl:value-of select="current()/first" /> </td> <td> <xsl:value-of select="current()/last" /> </td> <td> <xsl:value-of select="current()/dependentaddress" /> </td> <td> <xsl:value-of select="current()/dependentcity" /> </td> <td> <xsl:value-of select="current()/dependentstate" /> </td> <td> <xsl:value-of select="current()/dependentzip" /> </td> <td> <xsl:value-of select="current()/sex" /> </td> <td> <xsl:value-of select="current()/date-of-birth" /> </td> </tr> </xsl:template> <xsl:template match="subscriber"> <tr> <td>Gender:</td> <td> <xsl:value-of select="current()/sex" /> </td> </tr> <tr> <td>DOB:</td> <td> <xsl:value-of select="current()/date-of-birth" /> </td> </tr> <tr> <td>Patient Id:</td> <td> <xsl:value-of select="current()/patientid" /> </td> </tr> <tr> <td>Information Contact:</td> <td> <xsl:value-of select="current()/informationcontact" /> </td> </tr> </xsl:template> <xsl:template match="SummaryCoverages"> <table border="0"> <tr style="color: white" bgcolor="#2c689e"> <th>Eligibility</th> <th>Coverage Start Date</th> <th>Coverage End Date</th> </tr> <xsl:for-each select="current()/SummaryCoverage"> <xsl:sort select="CoverageStartDate" /> <tr> <td> <xsl:value-of select="VerifiedResponseType" /> </td> <td> <xsl:value-of select="CoverageStartDate" /> </td> <td> <xsl:value-of select="CoverageEndDate" /> </td> </tr> </xsl:for-each> </table> </xsl:template> </xsl:stylesheet>'
	;
INSERT INTO @Payers VALUES('36273','AARP Medicare Supplement by UnitedHealthcare',@CommercialXSL);
INSERT INTO @Payers VALUES('60054','Aetna',@CommercialXSL);
INSERT INTO @Payers VALUES('128KS','Aetna Better Health of Kansas',@CommercialXSL);
INSERT INTO @Payers VALUES('128KSMC','Aetna Better Health of Kansas (Medicaid Managed Care)',@CommercialXSL);
INSERT INTO @Payers VALUES('26375','Amerigroup',@CommercialXSL);
INSERT INTO @Payers VALUES('01757','AmFirst Insurance Company',@CommercialXSL);
INSERT INTO @Payers VALUES('ASRM1','ASRM LLC',@CommercialXSL);
INSERT INTO @Payers VALUES('75068','Assurant Health Self Funded',@CommercialXSL);
INSERT INTO @Payers VALUES('AUX01','Auxiant',@CommercialXSL);
INSERT INTO @Payers VALUES('SB650','BCBS Kansas',@CommercialXSL);
INSERT INTO @Payers VALUES('Z1226','Carelon Behavioral Health Strategies',@CommercialXSL);
INSERT INTO @Payers VALUES('68068','Cenpatico Behavioral Health',@CommercialXSL);
INSERT INTO @Payers VALUES('68069','Centene Health Plans',@CommercialXSL);
INSERT INTO @Payers VALUES('45564','Centivo',@CommercialXSL);
INSERT INTO @Payers VALUES('84146','CHAMPVA/VA-HAC',@CommercialXSL);
INSERT INTO @Payers VALUES('59355','Christian Care Ministries',@CommercialXSL);
INSERT INTO @Payers VALUES('62308','CIGNA (Connecticut General, Equicor, Equitable)',@CommercialXSL);
INSERT INTO @Payers VALUES('37363','ComPsych',@CommercialXSL);
INSERT INTO @Payers VALUES('00019','Cox Health Plan',@CommercialXSL);
INSERT INTO @Payers VALUES('06102','Diversified Administration',@CommercialXSL);
INSERT INTO @Payers VALUES('81039','Employee Benefit Management Services Inc (EBMS)',@CommercialXSL);
INSERT INTO @Payers VALUES('62324','Freedom Life Insurance Company',@CommercialXSL);
INSERT INTO @Payers VALUES('93158','Fringe Benefit Group MEC Plan',@CommercialXSL);
INSERT INTO @Payers VALUES('37602','Golden Rule Insurance Company',@CommercialXSL);
INSERT INTO @Payers VALUES('44054','Government Employees Health Association (GEHA)',@CommercialXSL);
INSERT INTO @Payers VALUES('GRV01','Gravie Administrative Services (DOS on or after 10/1/2022)',@CommercialXSL);
INSERT INTO @Payers VALUES('80241','Group Benefit Services',@CommercialXSL);
INSERT INTO @Payers VALUES('HPOUV','Health Plan of Upper Ohio Valley',@CommercialXSL);
INSERT INTO @Payers VALUES('44273','Health Plans Inc',@CommercialXSL);
INSERT INTO @Payers VALUES('73147','Healthcare Solutions Group (Muskogee OK)',@CommercialXSL);
INSERT INTO @Payers VALUES('61101','Humana (and subsidiaries) claims',@CommercialXSL);
INSERT INTO @Payers VALUES('48143','Imagine 360 Administrators',@CommercialXSL);
INSERT INTO @Payers VALUES('71066','Kansas Health Advantage',@CommercialXSL);
INSERT INTO @Payers VALUES('73100','Kempton Company',@CommercialXSL);
INSERT INTO @Payers VALUES('65085','Lucent Health - North America Administrators NAA',@CommercialXSL);
INSERT INTO @Payers VALUES('48117','Luminare Health KC (fka Trustmark Health Benefits)',@CommercialXSL);
INSERT INTO @Payers VALUES('35245','Marpai Health',@CommercialXSL);
INSERT INTO @Payers VALUES('56162','MedCost Preferred',@CommercialXSL);
INSERT INTO @Payers VALUES('SKKS0','Medicaid Kansas',@CommercialXSL);
INSERT INTO @Payers VALUES('SMKS0','Medicare B Kansas',@CommercialXSL);
INSERT INTO @Payers VALUES('41124','Meritain Health Minneapolis',@CommercialXSL);
INSERT INTO @Payers VALUES('NDX99','New Directions Behavioral Health',@CommercialXSL);
INSERT INTO @Payers VALUES('98999','Paper',@CommercialXSL);
INSERT INTO @Payers VALUES('88056','Premier HealthCare Exchange',@CommercialXSL);
INSERT INTO @Payers VALUES('48100','ProviDRs Care Network',@CommercialXSL);
INSERT INTO @Payers VALUES('SRRGA','Railroad Medicare',@CommercialXSL);
INSERT INTO @Payers VALUES('25463','Surest',@CommercialXSL);
INSERT INTO @Payers VALUES('23223','The Loomis Company',@CommercialXSL);
INSERT INTO @Payers VALUES('TDDIR','Tricare for Life',@CommercialXSL);
INSERT INTO @Payers VALUES('TRICW','Tricare West Region',@CommercialXSL);
INSERT INTO @Payers VALUES('39026','UMR',@CommercialXSL);
INSERT INTO @Payers VALUES('87726','United Healthcare',@CommercialXSL);
INSERT INTO @Payers VALUES('96385','UnitedHealthcare Community Plan Kansas (KanCare)',@CommercialXSL);
INSERT INTO @Payers VALUES('74227','UnitedHealthcare StudentResources',@CommercialXSL);
INSERT INTO @Payers VALUES('81400','UnitedHealthOne',@CommercialXSL);
INSERT INTO @Payers VALUES('VACCN','VA Community Care Network',@CommercialXSL);
INSERT INTO @Payers VALUES('75261','WebTPA Employer Services LLC',@CommercialXSL);


IF (@ElectronicEligibilityVerificationConfigurationId > 0)
BEGIN
	INSERT INTO ElectronicEligibilityVerificationPayers (
		CreatedBy
		,CreatedDate
		,ModifiedBy
		,ModifiedDate
		,ElectronicPayerId
		,ElectronicPayerName
		,ResponseXSL
		,ElectronicEligibilityVerificationConfigurationId
		)
	SELECT @UserCode
		,@CurrDateTime
		,@UserCode
		,@CurrDateTime
		,p.ElectronicPayerId
		,p.ElectronicPayerName
		,p.ResponseXSL
		,@ElectronicEligibilityVerificationConfigurationId
	FROM @Payers AS p
	WHERE NOT EXISTS (
			SELECT *
			--DELETE eevp
			FROM dbo.ElectronicEligibilityVerificationPayers AS eevp
			WHERE p.ElectronicPayerId = eevp.ElectronicPayerId
				AND p.ElectronicPayerName = eevp.ElectronicPayerName
				AND ISNULL(eevp.RecordDeleted, 'N') = 'N'
			);
END;
GO

/*
--Test Code

--DECLARE @MaxId int;

--SELECT @MaxId = MAX(ElectronicEligibilityVerificationPayerId) FROM dbo.ElectronicEligibilityVerificationPayers;
--SELECT @MaxId AS [@MaxId];
--IF @MaxId IS NULL
--BEGIN
--	SET @MaxId = 0;
--	SELECT @MaxId AS [New @MaxId];
--END;

--DBCC CHECKIDENT(ElectronicEligibilityVerificationPayers, RESEED, @MaxId);

--GO

*/
