/*
    Description: Batch is used to undelete records.
*/
public class BatchMassUndeleteRecords Implements Database.batchable<string>{
    
    List<String> lstIds;
    
    public BatchMassUndeleteRecords(List<String> lst){
        this.lstIds = lst;
    }
    
    public Iterable<String> start(Database.BatchableContext BC){
       return this.lstIds;
    }
    
    public void execute(Database.BatchableContext BC,List<string> lstRecords){
        List<Sobject> lstUndeleteAll = new List<Sobject>();
        Set<String> setRecIdsToRestore = new Set<String>();
        List<rbin__Deleted_Data__c> lstRecordsToDelete = new List<rbin__Deleted_Data__c>();
        Map<String, rbin__Deleted_Data__c> mapDeletedRecordIds = new Map<String, rbin__Deleted_Data__c>();

        for(string s : lstRecords){
            string[] strarr = s.split('#');
            if(strarr != null && strarr.size()>1){
                Sobject objS = Schema.getGlobalDescribe().get(strarr[0]).newSObject();
                objS.Put('Id',strarr[1]);
                lstUndeleteAll.add(objS);
                setRecIdsToRestore.add(strarr[1]);// store the record Ids that has to be restored to delete from permanently deteled data.

            }            
        }
        Database.UndeleteResult[] undeleteresults = Database.Undelete(lstUndeleteAll, true);
        
        if(setRecIdsToRestore.size() > 0){
        List<rbin__Deleted_Data__c> lstDeletedDataRecords = [Select rbin__Record_ID__c from rbin__Deleted_Data__c Where rbin__Record_ID__c in:setRecIdsToRestore WITH SECURITY_ENFORCED];
        
        for (rbin__Deleted_Data__c rec : lstDeletedDataRecords) {

            mapDeletedRecordIds.put(rec.rbin__Record_ID__c, rec);

        }
    }
        
        List<rbin__Error_Log__c> lstErrorRecords = new List<rbin__Error_Log__c>();
        for (Integer i = 0; i < undeleteresults.size(); i++) {
            if (undeleteresults[i].isSuccess()) {

                rbin__Deleted_Data__c deletedDataRec = mapDeletedRecordIds.get(undeleteresults[i].getId()); 

                if(deletedDataRec != null){
                    lstRecordsToDelete.add(mapDeletedRecordIds.get(undeleteresults[i].getId()));
                }
                
            } else {
                rbin__Error_Log__c errorObj = new rbin__Error_Log__c();
                errorObj.rbin__Error_Message__c = String.valueOf(undeleteresults[i].getErrors());
                errorObj.rbin__Failed_Record__c = String.valueOf(lstUndeleteAll[i]);
                lstErrorRecords.add(errorObj);
            }
        }

        insert lstErrorRecords;
        if(Schema.sObjectType.rbin__Deleted_Data__c.isdeletable() && lstRecordsToDelete.size() > 0){
            Delete lstRecordsToDelete;
            Database.EmptyRecyclebin(lstRecordsToDelete);
        }
        
    }
    
    public void finish(Database.BatchableContext BC){
    }
 }