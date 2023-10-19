public class batchCreateChildObjectRecords Implements Database.Batchable<sobject>, Database.Stateful{
    private Integer objectNo = 1;
    private Map<Integer,string> mapChildObjNames = new Map<Integer,string>();
    private Map<string,string> objectKeyFieldMap = new Map<string,string>();
    
    public batchCreateChildObjectRecords(Map<Integer,string> mapChildObj){
       this.mapChildObjNames.putAll(mapChildObj);
        system.debug('Map of child objects in child Batchclass'+this.mapChildObjNames);
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        
        set<string> setTrackingObjects = new set<string>();
        string objectName = mapChildObjNames.get(this.objectNo);
        string myQuery = '';
        //get Object Key field for Different Objects
        for(rbin__ObjectKeyField__mdt objectKeyFieldMdt : [Select id, MasterLabel, rbin__Field_Name__c From rbin__ObjectKeyField__mdt]){
            this.objectKeyFieldMap.put(objectKeyFieldMdt.MasterLabel, objectKeyFieldMdt.rbin__Field_Name__c);
        }
        for(rbin__Permanent_Deleted_Tracking_Object__c trackingObject:[Select Id, Name From rbin__Permanent_Deleted_Tracking_Object__c ]){
            setTrackingObjects.add(trackingObject.Name);
        }
        if(!setTrackingObjects.contains(objectName) && objectName!=null){
         List<String> fieldNames = new List<String>(UtilityCls.fetchObjectFieldMap(objectName).keySet());
        
          myQuery = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + objectName + ' WHERE IsDeleted = true ALL ROWS';
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
        this.objectNo++;
        batchCreateChildObjectRecords bt = new batchCreateChildObjectRecords(this.mapChildObjNames);
        Database.executeBatch(bt);
        
    }
}