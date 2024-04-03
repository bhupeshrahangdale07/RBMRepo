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
        for(string s : lstRecords){
            string[] strarr = s.split('#');
            if(strarr != null && strarr.size()>1){
                Sobject objS = Schema.getGlobalDescribe().get(strarr[0]).newSObject();
                objS.Put('Id',strarr[1]);
                lstUndeleteAll.add(objS);
            }            
        }
        Database.UndeleteResult[] undeleteresults = Database.Undelete(lstUndeleteAll,false);
        
        List<rbin__Error_Log__c> lstErrorRecords = new List<rbin__Error_Log__c>();
        for (Integer i = 0; i < undeleteresults.size(); i++) {
            if (undeleteresults[i].isSuccess()) {

               
            } else {
                rbin__Error_Log__c errorObj = new rbin__Error_Log__c();
                errorObj.rbin__Error_Message__c = String.valueOf(undeleteresults[i].getErrors());
                errorObj.rbin__Failed_Record__c = String.valueOf(lstUndeleteAll[i]);
                lstErrorRecords.add(errorObj);
            }
        }

        insert lstErrorRecords;
    }
    
    public void finish(Database.BatchableContext BC){
    }
 }