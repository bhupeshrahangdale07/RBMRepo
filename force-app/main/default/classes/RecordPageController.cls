/*
    Description: Detailed record page
*/
public with sharing class RecordPageController {
 
    public string objectname;
    public string recordid;
    
    public string ObjectLabelName {get; set;}
    public string ObjectLabelText {get; set;}
    public string RecordName {get; set;}
    public string Keyword {get; set;}    
    public string FromDate {get; set;}
    public string ToDate {get; set;}
    public string SelectedUser {get; set;}
    
    public List<WrapperRecordDetail> lstAllDetails {get; set;}
    
    public RecordPageController(){
        
        if(Apexpages.CurrentPage().getParameters().get('keyword') != null)
        {
            Keyword = string.escapeSingleQuotes( string.valueof(Apexpages.CurrentPage().getParameters().get('keyword')));
        }
        
        if(Apexpages.CurrentPage().getParameters().get('fromDate') != null)
        {
            FromDate = string.escapeSingleQuotes( string.valueof(Apexpages.CurrentPage().getParameters().get('fromDate')));
        }
        
        if(Apexpages.CurrentPage().getParameters().get('toDate') != null)
        {
            ToDate = string.escapeSingleQuotes( string.valueof(Apexpages.CurrentPage().getParameters().get('toDate')));
        }
        
        if(Apexpages.CurrentPage().getParameters().get('selectedUser') != null)
        {
            SelectedUser = string.escapeSingleQuotes( string.valueof(Apexpages.CurrentPage().getParameters().get('selectedUser')));
        }
        
        
        
        if(Apexpages.CurrentPage().getParameters().get('objectname') != null) {
            
            objectname =string.escapeSingleQuotes( string.valueof(Apexpages.CurrentPage().getParameters().get('objectname')));

        } else {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, 'Object Name is not found.');
            ApexPages.addMessage(msg); 
            return;  
        }
        if(Apexpages.CurrentPage().getParameters().get('id') != null) {
            recordid = string.valueof(Apexpages.CurrentPage().getParameters().get('id'));
        } else {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.Error, 'Record Id is not found.');
            ApexPages.addMessage(msg); 
            return;
        }
        LoadRecordDetail();
    }
    
    public void LoadRecordDetail(){
        ObjectLabelName  = '';
        RecordName = '';
        system.debug('recordid  ::: '+recordid);
        lstAllDetails = new List<WrapperRecordDetail>();
        if(string.isnotblank(objectname)) {

            Map<string,string>  mapFieldName = new Map<string,string>();
            for(rbin__ObjectKeyField__mdt o : [select id,MasterLabel,rbin__Field_Name__c from rbin__ObjectKeyField__mdt where id != null]){
                mapFieldName.put(o.MasterLabel,o.rbin__Field_Name__c);
            }
            string objectkeyfields = 'Name';
            if(mapFieldName.containsKey(objectname)){
                objectkeyfields = mapFieldName.get(objectname);
            }
        
            Map<String, Schema.SObjectField> objectFields = Schema.getGlobalDescribe().get(objectname).getDescribe().fields.getMap();
            
            ObjectLabelName = Schema.getGlobalDescribe().get(objectname).getDescribe().getName();
            ObjectLabelText = Schema.getGlobalDescribe().get(objectname).getDescribe().getLabel();
            
            List<String> fieldNames = new List<String>( objectFields.keySet() );
            string strQuery = '';
            if(Schema.getGlobalDescribe().get(objectname).getDescribe().isAccessible()) {
             	strQuery = 'Select '+ string.join(fieldNames, ',') + ' from '+ string.escapeSingleQuotes( objectname) +' Where Id=: recordid and IsDeleted = true ALL ROWS';   
            }
            
            List<SObject> lstSobjects = Database.Query(strQuery);
            
            Integer count = 0;
            if(lstSobjects.size() > 0) {
                SObject objSobject  = lstSobjects[0];
                for(string fieldapi: objectFields.keyset()){
                    
                    WrapperRecordDetail objWrapper = new WrapperRecordDetail();
                    Schema.DescribeFieldResult fieldtype = objectFields.get(fieldapi).getDescribe();
                    
                    if(fieldtype.isAccessible() && fieldtype.getType() != Schema.DisplayType.Address) {                        
                        if(fieldapi == objectkeyfields) {                         
                            if(string.valueof(objSobject.get(fieldapi)) != null && string.valueof(objSobject.get(fieldapi)) != ''){
                                RecordName = string.valueof(objSobject.get(fieldapi));
                            }
                        }
                        if(Math.Mod(count, 2) == 0) {
                            objWrapper.isHideRow = true;
                        } else {
                            objWrapper.isHideRow = false;
                        }
                        objWrapper.FieldAPIName = fieldapi;
                        objWrapper.FieldLabel = objectFields.get(fieldapi).getDescribe().getLabel();
                        if(objSobject.get(fieldapi) != null) {
                            objWrapper.Value = string.valueof(objSobject.get(fieldapi));
                        } else {
                            objWrapper.Value = '-';
                        }
                        lstAllDetails.add(objWrapper);
                        
                        count++;
                    }
                }
            }
           
        }
    }
    
    public PageReference UndeleteRecord(){
        try {
            Sobject objS = Schema.getGlobalDescribe().get(objectname).newSObject();
            objS.Put('Id',recordid);
            
            Database.UndeleteResult undeleteresult = Database.Undelete(objS, false);

            List<rbin__Deleted_Data__c> lstDeletedDataRecords = [Select rbin__Record_ID__c from rbin__Deleted_Data__c Where rbin__Record_ID__c =: recordid WITH SECURITY_ENFORCED];

            if(undeleteresult.isSuccess() && lstDeletedDataRecords.size() > 0 && Schema.sObjectType.rbin__Deleted_Data__c.isdeletable()){

                Delete lstDeletedDataRecords;
                Database.EmptyRecyclebin(lstDeletedDataRecords);

            }
            if(!undeleteresult.isSuccess()){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'This Record is in process of getting purged.',''));
                return null;
            }
            PageReference pg = new PageReference('/'+recordid);
            pg.setRedirect(true);
            return pg;
        } catch (Exception ex) {
                
              ApexPages.addMessages(ex);  
              
              if(ex.getmessage().contains('Entity is not in the recycle bin'))
               {                    
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,'Salesforce runs a process on a scheduled basis that physically deletes records that have been deleted from the recycle bin, if that process has not run yet, you will still see the records here.',''));
               }                      
            
            return null;
        }
    }
    
    public class WrapperRecordDetail {
        public string FieldAPIName {get; set;}
        public string FieldLabel {get; set;}
        public string Value {get; set;}
        public boolean isHideRow {get; set;} 
        public WrapperRecordDetail(){
            FieldAPIName = '';
            FieldLabel = '';
            Value = '';
            isHideRow = false;
        }
    }   
}