/*
// --------------------------------------------------------------------------------------------------------------

// This class used to create Permanent Delete record based on scheduled batch everyday.
// It is create only those which are deleted within in 24 hours.
// Version#     Date                            Author                                  Description
// --------------------------------------------------------------------------------------------------------------
// 1.0         27-07-2023                     Kandisa Technologies                    Initial Version 1.0
// --------------------------------------------------------------------------------------------------------------

*/

public class createPermanentDeletedRecordBatch Implements Database.Batchable<sobject>, Database.Stateful{
    
    public List<rbin__Track_Batch_Process__c> lstTrackBatchProcess = new List<rbin__Track_Batch_Process__c>();
    public Map<string,string> objectKeyFieldMap = new Map<string,string>();
    private Integer recordNo = 1;
    
    public createPermanentDeletedRecordBatch(Integer RecNo){
        this.recordNo = RecNo;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //get Object Key field for Different Objects
        for(rbin__ObjectKeyField__mdt objectKeyFieldMdt : [Select id, MasterLabel, rbin__Field_Name__c From rbin__ObjectKeyField__mdt]){
            this.objectKeyFieldMap.put(objectKeyFieldMdt.MasterLabel, objectKeyFieldMdt.rbin__Field_Name__c);
        }
        
        //TODO: use custom lable instead of direct name for where cluase like, Name.
        lstTrackBatchProcess = new List<rbin__Track_Batch_Process__c>([
            SELECT
            	rbin__Last_Run_Batch_Time__c
            FROM rbin__Track_Batch_Process__c
            WHERE Name = 'Track Permanent Deleted Data Batch'
        ]);
        
        //getting single objec from track deleted object data
        List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> lstTrackDeletedObjects = new List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c>([
            Select 
            	Id, 
            	Name,
            	rbin__Record_No__c 
            From rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c 
            Where rbin__Record_No__c = :recordNo Limit 1
        ]);
        
        String objName = (string)lstTrackDeletedObjects[0].get('Name');
        String myQuery = '';
        
        // fetch object fields
        List<String> fieldNames = new List<String>(UtilityCls.fetchObjectFieldMap(objName).keySet());
        
        if(lstTrackBatchProcess.size() > 0 && lstTrackBatchProcess[0].Last_Run_Batch_Time__c != null){
            DateTime lastRunBatch = lstTrackBatchProcess[0].rbin__Last_Run_Batch_Time__c;
            myQuery = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + objName + ' WHERE IsDeleted = true and LastModifiedDate > :lastRunBatch ALL ROWS';
        }
        return Database.getQueryLocator(myQuery); 
    }
    
    public void execute(Database.BatchableContext bc, List<SObject> sObjectRecords){
        string recordName;
        List<rbin__Deleted_Data__c> upsertToDeletedData = new List<rbin__Deleted_Data__c>();
        
        //get list of Ids from List
        Set<Id> sObjectRecordIds = (new Map<Id,SObject>(sObjectRecords)).keySet();
        
        if(sObjectRecords.size() > 0){
            Map<String,rbin__Deleted_Data__c> existingDeletedDataMap= new Map<String,rbin__Deleted_Data__c>();
            
            //fetch Existing Deleted Data
            for(rbin__Deleted_Data__c objDeletedData : [Select id,rbin__Record_ID__c,rbin__Record_Name__c,rbin__Deleted_By__c,rbin__Object_Name__c,rbin__Deleted_Date__c,rbin__Data__c from rbin__Deleted_Data__c where rbin__Record_ID__c in :sObjectRecordIds]){
                existingDeletedDataMap.put(objDeletedData.rbin__Record_ID__c, objDeletedData);  
            }
            
            for(SObject rec : sObjectRecords){
                //fetch/Assign new deleted record
                if(!existingDeletedDataMap.containsKey(rec.Id)){
                    if(objectKeyFieldMap.containsKey(String.valueOf(rec.getSObjectType()))){
                        recordName = (String)rec.get(objectKeyFieldMap.get(String.valueOf(rec.getSObjectType())));
                    }else{
                        recordName = (String)rec.get('Name');
                    }
                    
                    rbin__Deleted_Data__c newObject = new rbin__Deleted_Data__c();
                    newObject.rbin__Record_ID__c = rec.Id;  
                    newObject.rbin__Record_Name__c = recordName; 
                    newObject.rbin__Deleted_By__c = (String)rec.get('LastModifiedById');
                    newObject.rbin__Object_Name__c = String.valueOf(rec.getSObjectType());
                    newObject.rbin__Deleted_Date__c = (DateTime)rec.get('LastModifiedDate');
                    newObject.rbin__Data__c = JSON.serializePretty(rec);
                    
                    //insert new deleted record
                    upsertToDeletedData.add(newObject);
                }else{
                    //fetch existing deleted record
                    if(existingDeletedDataMap.containsKey(rec.Id)){
                        rbin__Deleted_Data__c existDeletedDataObj = new rbin__Deleted_Data__c();
                        
                        if(rec != null){
                            if(objectKeyFieldMap.containsKey(String.valueOf(rec.getSObjectType()))){
                                existDeletedDataObj.rbin__Record_Name__c = (String)rec.get(objectKeyFieldMap.get(String.valueOf(rec.getSObjectType())));
                            }else{
                                existDeletedDataObj.rbin__Record_Name__c = (String)rec.get('Name');
                            }
                            existDeletedDataObj.Id = rec.Id;
                            existDeletedDataObj.rbin__Deleted_Date__c = (DateTime)rec.get('LastModifiedDate');
                            existDeletedDataObj.rbin__Data__c = JSON.serializePretty(rec);
                        }
                        
                        //update new deleted record
                        upsertToDeletedData.add(existDeletedDataObj);
                    }
                }
            }
        }
		
        // Insert/Update Deleted Data
        Database.Upsert(upsertToDeletedData,false); 
    }
    
    public void finish(Database.BatchableContext bc){
        //get count of tracked delete objects
        Integer countTPDObjects = Database.countQuery('SELECT Count() FROM rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c');
        this.recordNo++;
        
        if(this.recordNo <= countTPDObjects){
            // run batch till complete all track Permanent Deleted Objects.
            createPermanentDeletedRecordBatch bt= new createPermanentDeletedRecordBatch(recordNo);
            Database.executeBatch(bt);
        }else{
            // Update last batch run on Track Batch Process setting.
            if(lstTrackBatchProcess.size() > 0){
                rbin__Track_Batch_Process__c objTrackBatchProcess = lstTrackBatchProcess[0];
                objTrackBatchProcess.rbin__Last_Run_Batch_Time__c = System.now();
                Update objTrackBatchProcess;
            }
        }
    }
}