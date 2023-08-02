public class BatchTrackPermntDeleteRecordData Implements Database.Batchable<sobject>{
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        return Database.getQueryLocator('Select Id, Name From rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c');
    }
    
    public void execute(Database.BatchableContext bc,List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> objList){
        
        List<SObject> recordList = new List<SObject>();
         List<Object> JsonDataList = new List<Object>();
        
        set<Sobject> objNames=new set<Sobject>();
        
        for(rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c cs:objList){
            system.debug('Name-'+cs.Name);
             
            
            string objName=cs.Name;
            SObjectType sObjType = ((SObject) Type.forName(objName).newInstance()).getSObjectType();
            Schema.SObjectType convertType = Schema.getGlobalDescribe().get(objName);
            Sobject genericObject = convertType.newSObject();
            objNames.add(genericObject);
            DescribeSObjectResult describeResult = genericObject.getSObjectType().getDescribe();
            system.debug('Object Names-'+genericObject);
            
            List<String> fieldNames = new List<String>( describeResult.fields.getMap().keySet() );
            //system.debug('Fields Names-'+fieldNames);
            String myQuery = ' SELECT ' +String.join( fieldNames, ',' ) +' FROM ' +describeResult.getName()+' Where IsDeleted=true ALL ROWS';
            
            system.debug('myQuery -'+myQuery);
            
             recordList.add(Database.query( myQuery ));
            //system.debug(recordList[0].Contact.Name);
            
            JsonDataList.add(JSON.serializePretty(recordList));
           
        }
        System.debug( recordList);
        system.debug('In Json-  '+JSON.serializePretty(recordList));
        
        //for(String obj : objNames){     
         for (SObject rec : recordList) {
            // Check if the SObject is of type Contact
            if (rec instanceof Contact) {
                Contact contactRecord = (Contact) rec;
                String recordid = contactRecord.Id;
                String recordName = contactRecord.Name;
                String deletedBy = contactRecord.LastModifiedById;
                //system.debug('Deleted by name -'+deletedBy);
               
                rbin__Deleted_Data__c newObject = new rbin__Deleted_Data__c();
        			newObject.rbin__Record_ID__c=recordid;
					newObject.rbin__Record_Name__c=recordName;
                	newObject.rbin__Deleted_By__c=deletedBy;
                	//newObject.rbin__Data__c=contactData;
                insert newObject;
        			
    }
         }
   // }
    }
    public void finish(Database.BatchableContext bc){
        
    }
}