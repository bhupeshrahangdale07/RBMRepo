public with sharing class permanentDeletedRecordPreviewController {

    
   @AuraEnabled(cacheable = true)
    public static wrpDeletedData showPreviewPage( Id recordId){

        wrpDeletedData objwrpDeletedData = new wrpDeletedData();
        
        system.debug('RecordId>>>'+recordId);
        
       List<wrpRecordDetail> lstDeletedRecord = new List<wrpRecordDetail>();
        rbin__Deleted_Data__c deletedRecord=[select id,rbin__Data__c,rbin__Record_ID__c,rbin__Object_Name__c,rbin__Record_Name__c from rbin__Deleted_Data__c where rbin__Record_ID__c=: recordId Limit 1];
        string deletedData=deletedRecord.rbin__Data__c;
        string objName=deletedRecord.rbin__Object_Name__c;
        string recName=deletedRecord.rbin__Record_Name__c;
        
        system.debug('JsonData-'+deletedData);
        Map<String, Object> jsonMap = (Map<String, Object>) JSON.deserializeUntyped(deletedData);
        
        //Map<String, Object> dataMap = new Map<String, Object>();
        for (String key : jsonMap.keySet()) {
            if (key != 'attributes' && key != 'BillingAddress' && key !='ShippingAddress') {
                 wrpRecordDetail objwr=new wrpRecordDetail();
                objwr.FieldLabel=key;
                system.debug('Label- '+key);
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
    public static Id restoreRecord(List<wrpRecordDetail> restoreData,string objName){
        try {
            sObject obj = Schema.getGlobalDescribe().get(objName).newSObject();
           set<String> allFieldName = new set<String>();
            Map<String, Schema.SobjectField> allMap = obj.getSObjectType().getDescribe().fields.getMap();
            for(Schema.SobjectField field : allMap.values())
            {
                
                Schema.DescribeFieldResult dfr = field.getDescribe();
                if(dfr.isCreateable() && dfr.isUpdateable())
                    allFieldName.add(dfr.getName());
            
            }
            system.debug('Set of fields- '+allFieldName);

            for(wrpRecordDetail rd:restoreData){
                if(allFieldName.contains(rd.FieldLabel) && rd.FieldLabel!='Id'){
                obj.put(rd.FieldLabel , rd.Value);
                
            }
            }
            system.debug('Object to insert- '+obj);
            insert obj;
            system.debug('New record Id- '+obj.Id);
            return obj.Id;
            
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
           // isHideRow = false;
        }
    } 
}