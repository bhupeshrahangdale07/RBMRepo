public class BatchTrackPermntDeleteRecordData Implements Database.Batchable<sobject>{
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('Select Id, Name From rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c');
    }
    
    public void execute(Database.BatchableContext bc,List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> objList){
        
        List<SObject> recordList = new List<SObject>();
         List<Object> JsonDataList = new List<Object>();
        List<SObject> newRecordList = new List<SObject>();
        //Map<SObjectType,Object> jsonMap = new Map<SObjectType,Object>();
        Map<Id, SObject> recordMap = new Map<Id, SObject>();
        set<string> objNames=new set<string>();
        
        for(rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c cs:objList){
            system.debug('Name-'+cs.Name);
            objNames.add(cs.Name); 
            
            string objName=cs.Name;
            }
        
        for (String objectName : objNames) {
            SObjectType sObjType = ((SObject) Type.forName(objectName).newInstance()).getSObjectType();
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(objectName);
            SObject genericObject = convertType.newSObject();
            DescribeSObjectResult describeResult = genericObject.getSObjectType().getDescribe();
            List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
			
            String myQuery = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + describeResult.getName() + ' WHERE IsDeleted = true ALL ROWS';
            	
            //recordList.add(Database.query(myQuery));
            for(SObject q:Database.query(myQuery)){
                recordList.add(q);
            }
            
           //jsonMap.put(sObjType,JSON.serializePretty(Database.query(myQuery)));
           
            String jsonData = JSON.serializePretty(recordList);
            //Filter out object data from the JSON array
             }
        for (SObject rec : recordList) {
                recordMap.put(rec.Id, rec);
            } 
        system.debug('Map of Records- '+recordMap);
        //system.debug('Map -'+jsonMap);
        set<Id> existRecordIds= new set<Id>();
        for(rbin__Deleted_Data__c existData:[Select id,rbin__Record_ID__c from rbin__Deleted_Data__c]){
            existRecordIds.add(existData.rbin__Record_ID__c);
        }
            for (Id recordId : recordMap.keySet()) {
               //create a record only if it's of the same type as the objectName
                SObject rec = recordMap.get(recordId);
                    
               // if (rec.getSObjectType() == objct) {
                if(!existRecordIds.contains(rec.Id)){
                    String recordName = (String)rec.get('Name');
                    String deletedBy = (String)rec.get('LastModifiedById');
                    String nameOfObject =String.valueOf(rec.getSObjectType());
                    DateTime deletedDate = (DateTime)rec.get('LastModifiedDate');
                    rbin__Deleted_Data__c newObject = new rbin__Deleted_Data__c();
                    newObject.rbin__Record_ID__c = rec.Id;  
                    newObject.rbin__Record_Name__c = recordName; 
                    newObject.rbin__Deleted_By__c = deletedBy;
                    newObject.rbin__Object_Name__c = nameOfObject;
                    newObject.rbin__Deleted_Date__c= deletedDate;
                    newObject.rbin__Data__c=JSON.serializePretty(rec);
                   
                     newRecordList.add(newObject);
                   
                //}
            }
                }
       
        /*system.debug('JsonData--');
        for(Object jData:JsonDataList){
                system.debug('JsonData -'+jData);
                
        Map<String, Object> objAttributes = (Map<String, Object>)jData;
        if (objAttributes.containsKey('attributes') && objAttributes.get('attributes') instanceof Map<String, Object>) {
            Map<String, Object> attributes = (Map<String, Object>)objAttributes.get('attributes');
            if (attributes.containsKey('type') && attributes.get('type') instanceof String) {
                String type = (String)attributes.get('type');
                //if (type.equals('Contact')) {
                    // Add the object to the contactDataList if it's a Contact
                   // contactDataList.add(obj);
                //}
                system.debug('Json Data-'+jData);
            }
        }
    
            }*/
         Database.insert(newRecordList,false);
    
    }
    public void finish(Database.BatchableContext bc){
        
    }
}