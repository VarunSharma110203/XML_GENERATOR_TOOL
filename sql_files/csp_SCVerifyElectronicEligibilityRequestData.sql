   
IF EXISTS ( SELECT  *
            FROM    sys.objects
            WHERE   [name] = 'csp_SCVerifyElectronicEligibilityRequestData' ) 
    DROP PROCEDURE csp_SCVerifyElectronicEligibilityRequestData
GO

CREATE PROCEDURE [dbo].[csp_SCVerifyElectronicEligibilityRequestData]    
    @ElectronicPayerId VARCHAR(25) ,    
    @SubscriberInsuredId [varchar](25) ,    
    @SubscriberFirstName [dbo].[type_FirstName] ,    
    @SubscriberLastName [dbo].[type_LastName] ,    
    @SubscriberSSN [dbo].[type_SSN] ,  -- optional for verification against gateway/edi    
    @SubscriberDOB [datetime] ,    
    @SubscriberSex [dbo].[type_Sex] ,    
    @DependentRelationshipCode VARCHAR(25),    
    @DependentFirstName [dbo].[type_FirstName] ,    
    @DependentLastName [dbo].[type_LastName] ,    
    @DependentDOB [datetime] ,    
    @DependentSex [dbo].[type_Sex] ,    
    @DateOfServiceStart [date] ,    
    @DateOfServiceEnd [date] ,    
 @SubscriberGroupNumber [varchar](10) = null    
AS -- =============================================    
-- Author:  Suhail Ali    
-- Create date: 1/13/2012    
-- Description:     
-- Validate eligibility verificaiton data to make sure all required data for 270 request has been provided.    
-- Pradeep: Validation added for Subscriber's DOB and Dependent's DOB with Current date.    
-- Veena:changed validation message for Payer Id and copied the sp to MFS custom folder
--27 Jan 2025		NithyaS		What: The @DependentRelationshipCode datatype has been changed from type_GlobalCode (Integer) to Varchar(25) to accommodate the possibility of alphanumeric relationship codes.
--								Why: As part of Nashua, 128522 task.
-- =============================================    
    BEGIN    
       
        DECLARE @ServiceDateStartString VARCHAR(20) = CAST(@DateOfServiceStart AS VARCHAR(20))    
        DECLARE @ServiceDateEndString VARCHAR(20) = CAST(@DateOfServiceEnd AS VARCHAR(20))    
    
        DECLARE @ValidationError TABLE    
            (    
              ErrorMessage VARCHAR(MAX)    
            )              
    
        IF ( @ElectronicPayerId IS NULL    
             OR LEN(LTRIM(@ElectronicPayerId)) < 2    
           )     
            INSERT  INTO @ValidationError    
                    ( ErrorMessage     
                    )    
            VALUES  ( 'Please select Electronic Payer.'    
                    )                               
            
    
        IF ( @SubscriberFirstName IS NULL    
             OR LEN(LTRIM(@SubscriberFirstName)) = 0    
           )     
            INSERT  INTO @ValidationError    
                    ( ErrorMessage     
                    )    
            VALUES  ( 'Subscriber''s first name must specified.'    
                    )    
                        
    
        IF ( @SubscriberLastName IS NULL    
             OR LEN(LTRIM(@SubscriberLastName)) = 0    
           )     
            INSERT  INTO @ValidationError    
                    ( ErrorMessage    
                    )    
            VALUES  ( 'Subscriber''s last name must specified.'    
                    )    
      
        /*IF ( ( @SubscriberDOB IS NULL )    
             AND ( @SubscriberInsuredId IS NULL    
                   OR LEN(LTRIM(@SubscriberInsuredId)) < 2    
                 )    
           )     
            INSERT  INTO @ValidationError    
                    ( ErrorMessage     
                    )    
            VALUES  ( 'At least either subscriber''s date of birth or insured id must be specified.'    
                    )*/    
  /*IF (@SubscriberInsuredId IS NULL    
    OR LEN(LTRIM(@SubscriberInsuredId))=0     
   )    
   INSERT  INTO @ValidationError    
                    ( ErrorMessage    
                    )    
            VALUES  ( 'Subscriber''s Insured Id must specified.'    
                    )*/    
  IF (convert(datetime ,@SubscriberDOB, 101) is not null     
   AND convert(datetime ,@SubscriberDOB, 101) > GETDATE()    
   )    
   INSERT INTO @ValidationError    
     (ErrorMessage    
     )    
   VALUES ( 'Subscriber''s data of birth cannot be greater than current date.'    
     )    
         
        IF ( @SubscriberSex IS NULL    
             OR @SubscriberSex NOT IN ( 'M', 'F' )    
           )     
            INSERT  INTO @ValidationError    
                    ( ErrorMessage     
                    )    
            VALUES  ( 'Subscriber''s gender must specified as ''M''ale or ''F''emale.'    
                    )    
                           
       
        IF ( ISNULL(@DependentRelationshipCode,'N')='N'   
   OR NOT EXISTS ( SELECT *    
                             FROM   dbo.GlobalCodes    
                             WHERE  Category = 'RELATIONSHIP'    
                                    AND ExternalCode1 = CAST(@DependentRelationshipCode AS VARCHAR) )    
           )     
            INSERT  INTO @ValidationError    
                    ( ErrorMessage     
                    )    
            VALUES  ( 'Subscriber''s relationship to insured must be specified and be a valid relationship code'    
                    )    
                        
    
        IF ( @DependentRelationshipCode <> '18'    
             AND EXISTS ( SELECT    *    
                          FROM      dbo.GlobalCodes    
                          WHERE     Category = 'RELATIONSHIP'    
                                    AND ExternalCode1 = CAST(@DependentRelationshipCode AS VARCHAR) )    
             AND ( @DependentFirstName IS NULL    
                   OR LEN(@DependentFirstName) = 0    
                   OR @DependentLastName IS NULL    
                   OR LEN(@DependentLastName) = 0    
                   OR @DependentDOB IS NULL    
                   OR LEN(@DependentDOB) = 0    
                   OR @DependentSex IS NULL    
                   OR LEN(@DependentSex) = 0    
                 )    
           )     
            INSERT  INTO @ValidationError    
                    ( ErrorMessage     
                    )    
            VALUES  ( 'Subscriber is not the insured. Dependent first name, last name, date of birth and gender must be specified.'    
                    )               
  IF (convert(datetime ,@DependentDOB, 101) is not null     
   AND convert(datetime ,@DependentDOB, 101) > GETDATE()    
   )    
   INSERT INTO @ValidationError    
     (ErrorMessage    
     )    
   VALUES ( 'Dependent''s data of birth cannot be greater than current date.'    
     )    
         
        IF ( @DateOfServiceStart IS NULL    
             OR @DateOfServiceEnd IS NULL    
             OR @DateOfServiceStart > @DateOfServiceEnd
             --OR CAST(@DateOfServiceEnd AS date) > cast(GETDATE() AS date)
           )     
            INSERT  INTO @ValidationError    
                    ( ErrorMessage     
                    )    
            VALUES  ( 'Service date start and end must be specified, the service start date ('    
                      + @ServiceDateStartString    
                      + ') must be before service end date ('    
                      + @ServiceDateEndString + ').'    
         
                    )    
        SELECT  ErrorMessage    
        FROM    @ValidationError    
    END    
GO