public class BatchTrackPermntDeleteRecordData Implements Database.Batchable<sobject>, Database.Stateful{
    
    public List<rbin__Track_Batch_Process__c> lstBatchProcess = new List<rbin__Track_Batch_Process__c>();
    private Integer recordNo;
    private String objectName;
    
    public BatchTrackPermntDeleteRecordData(){
        this.recordNo=1;  
    }
    public BatchTrackPermntDeleteRecordData(Integer RecNo){
        this.recordNo=RecNo;
    }
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        lstBatchProcess = new List<rbin__Track_Batch_Process__c>([
            SELECT
            rbin__Last_Run_Batch_Time__c
            FROM rbin__Track_Batch_Process__c
            WHERE Name = 'Track Permanent Deleted Data Batch'
        ]);
        
        List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> objList=[Select Id, Name,rbin__Record_No__c From rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c Where rbin__Record_No__c=:recordNo Limit 1];
        string objName=(string)objList[0].get('Name');
        objectName=objName;
        system.debug('objList'+objList);
        system.debug('Record No- '+recordNo);
        system.debug('objectName--> '+objectName);
        
        String myQuery;
        SObjectType sObjType = ((SObject) Type.forName(objName).newInstance()).getSObjectType();
        Schema.SObjectType convertType = Schema.getGlobalDescribe().get(objName);
        SObject genericObject = convertType.newSObject();
        DescribeSObjectResult describeResult = genericObject.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        
        if(lstBatchProcess.size() > 0 && lstBatchProcess[0].Last_Run_Batch_Time__c != null){
            DateTime lastRunBatch = lstBatchProcess[0].rbin__Last_Run_Batch_Time__c;
            myQuery = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + describeResult.getName() + ' WHERE IsDeleted = true and LastModifiedDate > :lastRunBatch ALL ROWS';
            system.debug('Query- '+myQuery);
        }
        return Database.getQueryLocator(myQuery); 
    }
    
    public void execute(Database.BatchableContext bc,List<SObject> recordList){
        string recordName;
        String deletedBy;
        String nameOfObject;
        DateTime deletedDate;
        //List<SObject> recordList = new List<SObject>();
        List<Object> JsonDataList = new List<Object>();
        List<rbin__Deleted_Data__c> newRecordList = new List<rbin__Deleted_Data__c>();
        List<rbin__Deleted_Data__c> updateRecordList = new List<rbin__Deleted_Data__c>();
        Map<Id, SObject> recordMap = new Map<Id, SObject>();
        //set<string> objNames=new set<string>();
        
        Map<string,string>  mapFieldName = new Map<string,string>();
        for(rbin__ObjectKeyField__mdt o : [select id,MasterLabel,rbin__Field_Name__c from rbin__ObjectKeyField__mdt where id != null]){
            mapFieldName.put(o.MasterLabel,o.rbin__Field_Name__c);
        }
        
       // Schema.DescribeSObjectResult objDescribe;
        String jsonData = JSON.serializePretty(recordList);
        //List<Schema.SObjectType> childObjects=new List<Schema.SObjectType>();
        
        if(recordList.size()>0){
            for (SObject rec : recordList) {
                recordMap.put(rec.Id, rec); 
            } 
           
           /* Schema.DescribeSObjectResult objectDescribe = Schema.getGlobalDescribe().get(objectName).getDescribe();
            List<Schema.ChildRelationship> childRelations = objDescribe.getChildRelationships();
            for(ChildRelationship c:childRelations){
                childObjects.add(c.getChildSObject());
            }*/
            system.debug('Map of Records- '+recordMap);
            
            set<Id> existRecordIds= new set<Id>();
            
            for(rbin__Deleted_Data__c existData:[Select id,rbin__Record_ID__c from rbin__Deleted_Data__c]){
                existRecordIds.add(existData.rbin__Record_ID__c);  
            }
            
            for (Id recordId : recordMap.keySet()) {
                
                SObject rec = recordMap.get(recordId);
                
                if(!existRecordIds.contains(rec.Id)){
                    if(mapFieldName.containsKey(String.valueOf(rec.getSObjectType()))){
                        
                        recordName = (String)rec.get(mapFieldName.get(String.valueOf(rec.getSObjectType())));
                        deletedBy = (String)rec.get('LastModifiedById');
                        nameOfObject =String.valueOf(rec.getSObjectType());
                        deletedDate = (DateTime)rec.get('LastModifiedDate');
                        
                    }else{
                        recordName = (String)rec.get('Name');
                        deletedBy = (String)rec.get('LastModifiedById');
                        nameOfObject =String.valueOf(rec.getSObjectType());
                        deletedDate = (DateTime)rec.get('LastModifiedDate');
                    }
                    rbin__Deleted_Data__c newObject = new rbin__Deleted_Data__c();
                    newObject.rbin__Record_ID__c = rec.Id;  
                    newObject.rbin__Record_Name__c = recordName; 
                    newObject.rbin__Deleted_By__c = deletedBy;
                    newObject.rbin__Object_Name__c = nameOfObject;
                    newObject.rbin__Deleted_Date__c= deletedDate;
                    newObject.rbin__Data__c=JSON.serializePretty(rec);
                    system.debug('Deleted Data- > '+JSON.serializePretty(rec));
                    newRecordList.add(newObject);
                    
                    
                }
            }
            
            for(rbin__Deleted_Data__c existData:[Select id,rbin__Record_ID__c,rbin__Record_Name__c,rbin__Deleted_By__c,rbin__Object_Name__c,rbin__Deleted_Date__c,rbin__Data__c from rbin__Deleted_Data__c where rbin__Record_ID__c in:existRecordIds]){
                
                SObject rec = recordMap.get(existData.rbin__Record_ID__c);
                rbin__Deleted_Data__c exObj=new rbin__Deleted_Data__c();
                
                if(rec !=null ){
                    if(mapFieldName.containsKey(String.valueOf(rec.getSObjectType()))){
                        exObj.Id=existData.Id;
                        //exObj.rbin__Record_ID__c=existData.rbin__Record_ID__c;
                        exObj.rbin__Record_Name__c=(String)rec.get(mapFieldName.get(String.valueOf(rec.getSObjectType())));
                        //exObj.rbin__Deleted_By__c=existData.rbin__Deleted_By__c;
                        //exObj.rbin__Object_Name__c=existData.rbin__Object_Name__c;
                        exObj.rbin__Deleted_Date__c=(DateTime)rec.get('LastModifiedDate');
                        system.debug('Rec- '+rec);
                        exObj.rbin__Data__c=JSON.serializePretty(rec);
                    }else{
                        exObj.Id=existData.Id;
                        //exObj.rbin__Record_ID__c=existData.rbin__Record_ID__c;
                        exObj.rbin__Record_Name__c=(String)rec.get('Name');
                        //exObj.rbin__Deleted_By__c=existData.rbin__Deleted_By__c;
                        //exObj.rbin__Object_Name__c=existData.rbin__Object_Name__c;
                        exObj.rbin__Deleted_Date__c=(DateTime)rec.get('LastModifiedDate');
                        system.debug('Rec- '+rec);
                        exObj.rbin__Data__c=JSON.serializePretty(rec);
                    }
                }
                updateRecordList.add(exObj);
            }
             
        }
        
        system.debug('Updated List-'+updateRecordList);
        Database.Insert(newRecordList,false);
        Database.Update(updateRecordList,false);
        
    }
    public void finish(Database.BatchableContext bc){
        List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> lstallObjRecords=[select id, Name from rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c];
        recordNo++;
        if(recordNo<=lstallObjRecords.size()){
        BatchTrackPermntDeleteRecordData bt= new BatchTrackPermntDeleteRecordData(recordNo);
        Database.executeBatch(bt);
        }else{
            rbin__Track_Batch_Process__c objBatch = lstBatchProcess[0];
        objBatch.rbin__Last_Run_Batch_Time__c = System.now();
        update objBatch;
        }
           
    }
    
    
}