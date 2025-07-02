IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   [name] = 'csp_SCGetElectronicEligibilityVerificationResponseText' ) 
    DROP PROCEDURE csp_SCGetElectronicEligibilityVerificationResponseText
GO

CREATE PROCEDURE csp_SCGetElectronicEligibilityVerificationResponseText
    @EligibilityVerificationRequestId AS INTEGER
AS 
-- =============================================
-- Author:		Suhail Ali
-- Create date: 1/13/2012
-- Description:	
-- Retrieve the eligibility response text for a given eligibility verificaiton request
-- =============================================
    BEGIN
        SELECT  hist.VerifiedResponseText
        FROM    dbo.ElectronicEligibilityVerificationRequests AS hist
        WHERE   EligibilityVerificationRequestId = @EligibilityVerificationRequestId
    END    
GO
