/****** Object:  StoredProcedure [dbo].[csp_RdlSubReportPSMedications]    Script Date: 11/27/2013 16:33:09 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[csp_RdlSubReportPSMedications]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[csp_RdlSubReportPSMedications]
GO

/****** Object:  StoredProcedure [dbo].[csp_RdlSubReportPSMedications]    Script Date: 11/27/2013 16:33:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[csp_RdlSubReportPSMedications]       
            
@DocumentVersionId  int 
AS                 
Begin          
/*                
** Object Name:  [csp_RdlSubReportPSMedications]                
**                
**                
** Notes:  Accepts two parameters (DocumentId & Version) and returns a record set                 
**    which matches those parameters.                 
**                
** Programmers Log:                
** Date  Programmer  Description                
**------------------------------------------------------------------------------------------                
** Get Data From     DiagnosesIAndII,DiagnosisDSMDescriptions      
** Oct 16 2007 Ranjeetb               
avoss corrected joins and added additonal columns
   
exec dbo.csp_RdlSubReportPSMedications 1200006
************************************************************************************
**  Update History
************************************************************************************
**  Date:			Author:				Description:
**  --------		--------			------------------------------------------- 
**	06/10/2025		Arul Sonia			Modified for pulling only the valid records Kansas Mental, 130227 (CUSTOMER TICKET 514445)
*/                


Select 
HRMAssessmentMedicationId,

DocumentVersionId,
Name,
Dosage,
Purpose,
PrescribingPhysician
From 
CustomHRMAssessmentMedications where DocumentVersionId=@DocumentVersionId AND ISNULL(RecordDeleted, 'N') = 'N'
    

    
--Checking For Errors                  
  If (@@error!=0)                  
  Begin                  

      RAISERROR ('csp_RdlSubReportPSMedications failed.  Please contact your system administrator. We apologize for the inconvenience.',16,1)                   
   Return                  
   End                  
           
                
      
End

--select Top 1 * from DiagnosesIAndII order by createddate desc


GO


