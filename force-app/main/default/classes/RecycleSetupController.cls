public with sharing class RecycleSetupController{
   
    public rbin__Recycle_Bin_Setting__c rbinsetting{get;set;}
    
    public RecycleSetupController(){
        rbinsetting = rbin__Recycle_Bin_Setting__c.getOrgDefaults();
    }
    
     public PageReference Save(){
        try {
            if(rbinsetting.Record_Limits__c > 6000){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ' You cannot display more than 6000 records on the Recycle Bin Page.',''));
            }else{
        
                update rbinsetting;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, ' Settings updated successfully!',''));
            
            }
            
        } catch (Exception ex) {
                
            ApexPages.addMessages(ex);  
            
        }
        return null;
    }
    
    
    
}