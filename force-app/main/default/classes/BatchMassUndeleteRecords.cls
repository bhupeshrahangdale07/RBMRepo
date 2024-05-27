/*
    Description: Batch is used to undelete records.
*/
public class BatchMassUndeleteRecords Implements Database.batchable<string>, Database.Stateful{
    
    List<String> lstIds;
    Integer totalRecordProcessed = 0;
    Integer totalFailedRecords = 0;
    Integer totalSuccessRecords = 0;
    
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
        Database.UndeleteResult[] undeleteresults = Database.Undelete(lstUndeleteAll, false);
        
        if(setRecIdsToRestore.size() > 0){
        List<rbin__Deleted_Data__c> lstDeletedDataRecords = [Select rbin__Record_ID__c from rbin__Deleted_Data__c Where rbin__Record_ID__c in:setRecIdsToRestore WITH SECURITY_ENFORCED];
        
        for (rbin__Deleted_Data__c rec : lstDeletedDataRecords) {

            mapDeletedRecordIds.put(rec.rbin__Record_ID__c, rec);

        }
    }
        
        List<rbin__Error_Log__c> lstErrorRecords = new List<rbin__Error_Log__c>();
        for (Integer i = 0; i < undeleteresults.size(); i++) {

            totalRecordProcessed += 1;

            if (undeleteresults[i].isSuccess()) {

                totalSuccessRecords += 1;
                rbin__Deleted_Data__c deletedDataRec = mapDeletedRecordIds.get(undeleteresults[i].getId()); 

                if(deletedDataRec != null){
                    lstRecordsToDelete.add(mapDeletedRecordIds.get(undeleteresults[i].getId()));
                }
                
            } else {

                totalFailedRecords +=1;
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

        List<String> sendtomails = new List<String>();
        String UserEmail = UserInfo.getUserEmail();

        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
            sendtomails.add(UserEmail); // Add email of system admin
        
        email.saveAsActivity = false;
        //email.setTargetObjectId(UserInfo.getUserId());
        email.setToAddresses(sendtomails);
        email.setSubject('Batch Restore Records Status');
        
        String body = 'Hi Admin, <br/><br/>' + UserInfo.getName() + ' has processed total ' + totalRecordProcessed + ' for restore. <br/><br/>Below is the details of restored Records,<br/><br/><table border="1" style="border-collapse: collapse; width: 50%; "><tr><th>Description</th><th>Count</b>&nbsp;&nbsp;';
        
        body += '</th></tr><tr style = "text-align: center;"><td>Success Records &nbsp;&nbsp;</td><td>&nbsp;&nbsp;' + totalSuccessRecords + '</td></tr><tr style="text-align: center;"><td>Failed Records</td><td>&nbsp;&nbsp;'+ totalFailedRecords +'</td></tr></table><br/>';
        
        body += '**Please check the <a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+Schema.SObjectType.rbin__Error_Log__c.getKeyPrefix()+'/o'+'">\'Error Log\'</a> for failed records in RBM app.<br/><br/>Thanks,<br/>Recycle Bin Manager';
        email.setHtmlBody(body);

            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });

    }
 }