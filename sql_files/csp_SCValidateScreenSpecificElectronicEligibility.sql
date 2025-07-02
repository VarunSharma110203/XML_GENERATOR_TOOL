/****** Object:  StoredProcedure [dbo].[csp_SCValidateScreenSpecificElectronicEligibility]    Script Date: 04/18/2014 08:42:27 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_SCValidateScreenSpecificElectronicEligibility]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[csp_SCValidateScreenSpecificElectronicEligibility]
GO


/****** Object:  StoredProcedure [dbo].[csp_SCValidateScreenSpecificElectronicEligibility]    Script Date: 04/18/2014 08:42:27 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[csp_SCValidateScreenSpecificElectronicEligibility]
    @ScreenId AS INT ,
    @ClientId AS INT ,
    @InquiryId AS INT ,
    @ElectronicPayerId AS VARCHAR(25) ,
    @SubscriberInsuredId AS VARCHAR(25) ,
    @SubscriberFirstName AS type_FirstName_Encrypted ,
    @SubscriberLastName AS type_LastName_Encrypted ,
    @SubscriberSSN AS type_SSN_Encrypted ,
    @SubscriberDOB AS DATETIME ,
    @SubscriberSex AS type_Sex ,
    @DependentRelationshipCode AS VARCHAR(25) ,
    @DependentFirstName AS type_FirstName_Encrypted ,
    @DependentLastName AS type_LastName_Encrypted ,
    @DependentDOB AS DATETIME ,
    @DependentSex AS type_Sex ,
    @DateOfServiceStart AS DATE ,
    @DateOfServiceEnd AS DATE
AS -- =============================================
-- Author:		Suhail Ali
-- Create date: 1/13/2012
-- Description:	
-- Validate registration and inquiry screen data for fitness to run electronic eligibility
--27 Jan 2025		NithyaS		What: The @DependentRelationshipCode datatype has been changed from type_GlobalCode (Integer) to Varchar(25) to accommodate the possibility of alphanumeric relationship codes.
--								Why: As part of Core Bugs, 130606 task.
-- =============================================
    BEGIN
        DECLARE @AllowableHoursSinceLastVerified INT
        DECLARE @ElectronicPayerName VARCHAR(100)
        DECLARE @ScreenName VARCHAR(100)
        
        SELECT  @ScreenName = ProcessName
        FROM    dbo.ElectronicEligibilityValidationProcesses
        WHERE   ScreenId = @ScreenId
        
        SELECT  @AllowableHoursSinceLastVerified = AllowableHoursSinceLastVerified
        FROM    dbo.ElectronicEligibilityVerificationConfigurations
		
        SELECT  @ElectronicPayerName = ElectronicPayerName
        FROM    dbo.ElectronicEligibilityVerificationPayers
        WHERE   ElectronicPayerId = @ElectronicPayerId
		
        DECLARE @ValidationError TABLE
            (
              ErrorMessage VARCHAR(MAX)
            )          

        IF @ScreenName IN ( 'Registration', 'Inquiry' )
            AND EXISTS ( SELECT *
                         FROM   dbo.ElectronicEligibilityVerificationRequests
                         WHERE  RequestReturnCode = 0
                                AND VerifiedOnDate > DATEADD(hh,
                                                             @AllowableHoursSinceLastVerified
                                                             * -1, GETDATE())
                                AND (ClientId = @ClientId
									OR (@ClientId IS NULL
										AND SubscriberFirstName = @SubscriberFirstName
										AND SubscriberLastName = @SubscriberLastName
										AND (@SubscriberDOB IS NOT NULL OR LEN(@SubscriberDOB) > 2 OR LEN(@SubscriberSSN) > 8 OR @SubscriberSSN IS NOT NULL)
										AND ( SubscriberDOB = @SubscriberDOB
											  OR SubscriberSSN = @SubscriberSSN
											) 
										)
									)
						)
                                    
            INSERT  INTO @ValidationError
                    ( ErrorMessage 
                    )
            VALUES  ( 'An electronic eligibility verification has already occurred for this member within the past '
                      + CAST( ( @AllowableHoursSinceLastVerified / 24 ) AS VARCHAR)
                      + ' days.  Please verify the member’s coverage utilizing a different method.'  			          
                    )                           

        --IF @ScreenName IN ( 'Inquiry' )
        --    AND EXISTS ( SELECT *
        --                 FROM   dbo.CoveragePlans cvg
        --                        INNER JOIN dbo.ClientCoveragePlans clientcvg ON clientcvg.CoveragePlanId = cvg.CoveragePlanId
        --                        INNER JOIN dbo.ClientCoverageHistory AS clientcvghist ON clientcvghist.ClientCoveragePlanId = clientcvg.ClientCoveragePlanId
        --                 WHERE  clientcvg.ClientId = @ClientId ) 
        --    INSERT  INTO @ValidationError
        --            ( ErrorMessage 
        --            )
        --    VALUES  ( 'The ‘Client Plans and Time Spans’ screen indicates that this member has '
        --              + @ElectronicPayerName
        --              + ' and eligibility verification is not necessary. If any changes to the member’s '
        --              + @ElectronicPayerName
        --              + 'are required, please specify if the ‘Additional Coverage Information’ text box.'
        --            )                                                    

        IF @ScreenName IN ( 'Inquiry' )
            AND ( ( @SubscriberFirstName IS NULL
                    OR @SubscriberLastName IS NULL
                  )
                  OR ( @SubscriberSSN IS NULL
                       AND @SubscriberDOB IS NULL
                     )
                ) 
            INSERT  INTO @ValidationError
                    ( ErrorMessage 
                    )
            VALUES  ( 'Please enter Insured Id OR enter a combination of First Name and Last Name with either SSN or DOB before proceeding.'
                    )
		
		-- Return any and all validation error messages
        SELECT  ErrorMessage
        FROM    @ValidationError
    END    




GO

