public with sharing class permanentDeletedRecordPreviewController {

    
   @AuraEnabled(cacheable = true)
    public static wrpDeletedData showPreviewPage( Id recordId){

        wrpDeletedData objwrpDeletedData = new wrpDeletedData();
        
        system.debug('RecordId>>>'+recordId);
        
       List<wrpRecordDetail> lstDeletedRecord = new List<wrpRecordDetail>();
        rbin__Deleted_Data__c deletedRecord=[select id,rbin__Record_ID__c,rbin__Object_Name__c,rbin__Record_Name__c from rbin__Deleted_Data__c where rbin__Record_ID__c=: recordId Limit 1];
        ContentVersion cv=[SELECT Id, ContentDocumentId,VersionData,Title FROM ContentVersion WHERE Title =:recordId];

        string deletedData=(cv.VersionData).toString();
        string objName=(String)Schema.getGlobalDescribe().get(deletedRecord.rbin__Object_Name__c).getDescribe().getLabel();
        string recName=deletedRecord.rbin__Record_Name__c;
        
        system.debug('JsonData-'+deletedData);
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(deletedData);

        // Query for object describe information
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(deletedRecord.rbin__Object_Name__c).getDescribe().fields.getMap();
        //Map<String, Object> dataMap = new Map<String, Object>();
        for (String key : jsonMap.keySet()) {
            if (key != 'attributes' && key != 'BillingAddress' && key !='ShippingAddress' && key !='MailingAddress') {
                 wrpRecordDetail objwr=new wrpRecordDetail();
                objwr.FieldLabel=fieldMap.get(key).getDescribe().getLabel();
                system.debug('Label- '+objwr.FieldLabel);
                if(jsonMap.get(key) != null) {
                    system.debug('Value- '+String.valueOf(jsonMap.get(key)));
                            objwr.Value = String.valueOf(jsonMap.get(key));
                        } else {
                            objwr.Value = '-';
                        }
                lstDeletedRecord.add(objwr);
                system.debug('Wrapper Obj>>'+objwr);
            }
        }
        system.debug('List of wrapper- '+lstDeletedRecord);
        objwrpDeletedData.lstWrpData = lstDeletedRecord;
        objwrpDeletedData.objectName = objName;
        objwrpDeletedData.recordName = recName;

        return objwrpDeletedData;

    }

    @AuraEnabled
    public static Id restoreRecord(Id recordId){
        try {

            set<String> allFieldName = new set<String>();
            rbin__Deleted_Data__c previewRecord=[select id,rbin__Record_ID__c,rbin__Object_Name__c,rbin__Record_Name__c from rbin__Deleted_Data__c where rbin__Record_ID__c=: recordId Limit 1];
            ContentVersion cv=[SELECT Id, ContentDocumentId,VersionData,Title FROM ContentVersion WHERE Title =:recordId];
            
            string deletedData=(cv.VersionData).toString();
            string objName=previewRecord.rbin__Object_Name__c;
            string recName=previewRecord.rbin__Record_Name__c;
            
            system.debug('JsonData-'+deletedData);
            sObject obj = Schema.getGlobalDescribe().get(objName).newSObject();
            Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(deletedData);

            Map<String, Schema.SobjectField> allMap = obj.getSObjectType().getDescribe().fields.getMap();
            For(Schema.SobjectField field : allMap.values()){
                Schema.DescribeFieldResult dfr = field.getDescribe();
                if(dfr.isCreateable() && dfr.isUpdateable()){
                    allFieldName.add(dfr.getName());
                }else if(dfr.getRelationshipOrder() == 1 || dfr.getRelationshipOrder() == 0){
                    allFieldName.add(dfr.getName());
                }
            }

            for(String fieldName:jsonMap.keySet()){

                if (allFieldName.contains(fieldName) && fieldName != 'Id') {
                    Schema.DescribeFieldResult fieldDescribe = allMap.get(fieldName).getDescribe();
                    if (fieldDescribe.getType() == Schema.DisplayType.DATE) {
                        Date fieldValue = Date.valueOf(String.valueOf(jsonMap.get(fieldName)));
                        obj.put(fieldName, fieldValue);
                    } else {
                        obj.put(fieldName, jsonMap.get(fieldName));
                    }
                }
            }

            system.debug('Object to insert- '+obj);

            TimeZone tz = UserInfo.getTimeZone();
                DateTime dt = Datetime.now();
                DateTime currentDt=dt.addSeconds((tz.getOffset(dt)/1000));

                Database.SaveResult sr = Database.insert(obj, false);
                Id recId;
                if (sr.isSuccess()) {
                    // Record was successfully inserted
                    System.debug('Account ID: ' + sr.getId());
                    recId = sr.getId();
                    previewRecord.rbin__Restored_Record_Id__c =sr.getId();
                    previewRecord.rbin__Has_Restored__c =true;
                    //previewRecord.rbin__Restored_Date_Time__c =currentDt;
                        update previewRecord;
                        delete previewRecord;
                        return recId;
                } else {
                    // Handle errors
                    for (Database.Error error : sr.getErrors()) {
                        System.debug('Error message: ' + error.getMessage());
                        System.debug('Error field: ' + error.getFields());
                    }
                    return recId;
                }
                    // return sr.getId();
        
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public class wrpDeletedData{
        @AuraEnabled
        public List<wrpRecordDetail> lstWrpData = null;
        @AuraEnabled
        public string objectName {get; set;}
        @AuraEnabled
        public string recordName {get; set;}
        
    }
    


    //WrapperRecordDetailFroPreview
    public class wrpRecordDetail {
        //public string FieldAPIName {get; set;}
        @AuraEnabled
        public string FieldLabel {get; set;}
        @AuraEnabled
        public string Value {get; set;}
        //public boolean isHideRow {get; set;} 
        public wrpRecordDetail(){
            //FieldAPIName = '';
            FieldLabel = '';
            Value = '';
           
        }
    } 
}