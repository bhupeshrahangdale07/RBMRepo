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
    private set<string> setChildObjToIgnore  = new set<string>();
    private Integer recordNo = 1;
    private string objectName;
    private Map<Integer,string> mapChildObjects = new Map<Integer,string>();
    
    public createPermanentDeletedRecordBatch(Integer RecNo){
        this.recordNo = RecNo;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //get Object Key field for Different Objects
        for(rbin__ObjectKeyField__mdt objectKeyFieldMdt : [Select id, MasterLabel, rbin__Field_Name__c From rbin__ObjectKeyField__mdt]){
            this.objectKeyFieldMap.put(objectKeyFieldMdt.MasterLabel, objectKeyFieldMdt.rbin__Field_Name__c);
        }
        for(rbin__Objects_To_Ignore__mdt obj : [Select id, MasterLabel from rbin__Objects_To_Ignore__mdt]){
            setChildObjToIgnore.add(obj.MasterLabel);
        }
        
        //TODO: use custom lable instead of direct name for where cluase like, Name.
        lstTrackBatchProcess = new List<rbin__Track_Batch_Process__c>([
            SELECT
            rbin__Last_Run_Batch_Time__c
            FROM rbin__Track_Batch_Process__c
            WHERE Name = 'Track Permanent Deleted Data Batch'
        ]);
        
        //getting single object from track deleted object data
        List<rbin__Permanent_Deleted_Tracking_Object__c> lstTrackDeletedObjects = new List<	rbin__Permanent_Deleted_Tracking_Object__c>([
            Select 
            Id, 
            Name,
            rbin__Record_No__c 
            From 	rbin__Permanent_Deleted_Tracking_Object__c 
            Where rbin__Record_No__c = :recordNo Limit 1
        ]);
        
        String objName = (string)lstTrackDeletedObjects[0].get('Name');
        objectName = objName;
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
        List<Schema.SObjectType> childObjects=new List<Schema.SObjectType>();
        //get list of Ids from List
        Set<Id> sObjectRecordIds = (new Map<Id,SObject>(sObjectRecords)).keySet();
        Map<string,string> mapRecordData = new Map<string,string>();
        //Map<string,string> mapExistRecordData = new Map<string,string>();
        set<string> setExistedRecordIds = new set<string>();
        
        if(sObjectRecords.size() > 0){
            Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
            List<Schema.ChildRelationship> childRelations = objectDescribe.getChildRelationships();
            /* for(ChildRelationship c:childRelations){
			childObjects.add(c.getChildSObject());
			mapChildObjects.put();
			}*/
            Integer objNumber = 1;
            for(Integer i=1; i<=childRelations.size(); i++){
                if(childRelations[i-1].isCascadeDelete() && childRelations[i-1].getChildSObject().getDescribe().isDeletable()){
                    string childObjName=string.valueOf(childRelations[i-1].getChildSObject());
                    if(!setChildObjToIgnore.contains(childObjName)){
                        this.mapChildObjects.put(objNumber,childObjName);
                        objNumber++;
                    }
                }
            }
            system.debug('Map Child Obj Names '+mapChildObjects);
            //system.debug('Child Object Names- '+ childObjects);
            
            Map<String,rbin__Deleted_Data__c> existingDeletedDataMap= new Map<String,rbin__Deleted_Data__c>();
            
            //fetch Existing Deleted Data
            for(rbin__Deleted_Data__c objDeletedData : [Select id,rbin__Record_ID__c,rbin__Record_Name__c,rbin__Deleted_By__c,rbin__Object_Name__c,rbin__Deleted_Date__c from rbin__Deleted_Data__c where rbin__Record_ID__c in :sObjectRecordIds]){
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
                    //newObject.rbin__Data__c = JSON.serializePretty(rec);
                    mapRecordData.put(rec.Id,JSON.serializePretty(rec));
                    setExistedRecordIds.add(rec.Id);
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
                            existDeletedDataObj.Id = existingDeletedDataMap.get(rec.Id).Id;
                            existDeletedDataObj.rbin__Deleted_Date__c = (DateTime)rec.get('LastModifiedDate');
                            //existDeletedDataObj.rbin__Data__c = JSON.serializePretty(rec);
                            mapRecordData.put(rec.Id,JSON.serializePretty(rec));
                            setExistedRecordIds.add(rec.Id);
                            
                        }
                        
                        //update new deleted record
                        upsertToDeletedData.add(existDeletedDataObj);
                    }
                }
            }
        }
        
        // Insert/Update Deleted Data
        Database.Upsert(upsertToDeletedData,false);
        
        UtilityCls.createFileAttachment(mapRecordData,setExistedRecordIds);
        
    }
    
    public void finish(Database.BatchableContext bc){
        //get count of tracked delete objects
        Integer countTPDObjects = Database.countQuery('SELECT Count() FROM 	rbin__Permanent_Deleted_Tracking_Object__c');
        this.recordNo++;
        if(!this.mapChildObjects.isEmpty()){
                 system.debug('Inside calling batch');
            batchCreateChildObjectRecords childBatch= new batchCreateChildObjectRecords(this.mapChildObjects);
            database.executeBatch(childBatch);
            }
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
    
    /*private static void createFileAttachment(Map<string,string> mapDeletedData,set<string> setRecIds){
        system.debug('Rec Ids'+setRecIds);
        List<contentDocument> existedContentDoc =[select id, Title from contentDocument where Title In: setRecIds];
        delete existedContentDoc;
        
        Map<String,Id> mapContentVersion=new Map<String,String>();      
        List<ContentVersion> lstContentVersion=new List<ContentVersion>();
        List<ContentDocumentLink> lstContentDocLnk= new List<ContentDocumentLink>();
        for(rbin__Deleted_Data__c insertedDeletedData:[select id,rbin__Record_ID__c from rbin__Deleted_Data__c where rbin__Record_ID__c in: mapDeletedData.keySet()]){
            ContentVersion cVersion = new ContentVersion();
            cVersion.ContentLocation = 'S'; 
            cVersion.PathOnClient = insertedDeletedData.rbin__Record_ID__c+'.txt';
            cVersion.Origin = 'H';
            cVersion.Title = insertedDeletedData.rbin__Record_ID__c;
            Blob body = Blob.valueOf(mapDeletedData.get(insertedDeletedData.rbin__Record_ID__c));
            cVersion.VersionData = body;
            lstContentVersion.add(cVersion);
            mapContentVersion.put(cVersion.Title,insertedDeletedData.Id);
        }
        insert lstContentVersion;
        
        for(string title:mapContentVersion.keySet()){
            ContentDocumentLink cdl = new ContentDocumentLink();
            system.debug('List of content version-'+[SELECT Id, ContentDocumentId,Title FROM ContentVersion WHERE Title =: title]);
            cdl.ContentDocumentId = [SELECT Id, ContentDocumentId,Title FROM ContentVersion WHERE Title =: title].ContentDocumentId;
            cdl.LinkedEntityId = mapContentVersion.get(title);
            cdl.ShareType = 'V'; 
            lstContentDocLnk.add(cdl);
        }
        insert lstContentDocLnk;
    }*/
}