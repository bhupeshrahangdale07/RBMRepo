public with sharing class trackPermanentDalateDataController {
    
    
    @AuraEnabled(cacheable = true)
    public static Map<string,string> getAllObjectName(){

        Map<string,string> mapOfAllObj = new Map<string,string>();
        List<String> ignorsObjects = new List<String>{'Partner','CaseComment','FeedComment','FeedItem','IdeaComment','FeedComment','FeedItem','EngagementChannelType','DataUsePurpose'};
        String endpoint = URL.getSalesforceBaseUrl().toExternalForm()+'/services/data/v48.0/sobjects/';
        HttpRequest req = new HttpRequest();
        endpoint += '';
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        Http httpreq = new Http();
        HttpResponse  res  = httpreq.send(req);
        Map<String, Object> m = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        List<Object> ob = (List<Object>)m.get('sobjects');
        for(Object o : ob){
            Map<String, Object> real = (Map<String, Object>)o;
            if((Boolean)real.get('triggerable')){
                if(!ignorsObjects.contains(String.valueOf(real.get('name')))){
                   
                    //trackingobject trackobj = new trackingobject();
                    String objLabel = String.valueOf(real.get('label'));
                    String name = String.valueOf(real.get('name'));
                    SObjectType schemaType = Schema.getGlobalDescribe().get(String.valueOf(real.get('name')));
                    if(schemaType != null){
                    if(schemaType.getDescribe().isAccessible() && schemaType.getDescribe().isDeletable() && schemaType.getDescribe().isQueryable() && !schemaType.getDescribe().isCustomSetting()) {
                    String label = String.valueOf(real.get('label'));
                        mapOfAllObj.put(name,label);  
                    } 
                        }
                }
            }
           
        }
        
        return mapOfAllObj;
         
    }

    @AuraEnabled
    public static string saveTrackingObject(List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> objNameList){
        try {
            List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> prmntObjectTrackingList = new List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c>();

            // Query for the maximum existing serial number
            List<AggregateResult> ar = [SELECT MAX(rbin__Record_No__c) maxRecordNo FROM rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c];
            Decimal maxSerialNumber = (Decimal)ar[0].get('maxRecordNo');
            system.debug('Max Record No- '+maxSerialNumber);
    // Increment by 1 to get the next serial number
    Decimal nextSerialNumber = maxSerialNumber + 1;
            
            for(rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c objName : objNameList){

                rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c prmntTrckObj = new rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c();

                prmntTrckObj.Name = objName.Name;
                system.debug('Name'+objName.Name);
                // Set the calculated serial number
            prmntTrckObj.rbin__Record_No__c = nextSerialNumber++;

                prmntObjectTrackingList.add(prmntTrckObj);
                
            }
            insert prmntObjectTrackingList;
            //updateSerialNumbers();
            return 'Setting Updated Successfully!';
            
        } catch (Exception e) {
            system.debug('Error in Line Number-'+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
            

        }
    }

    @AuraEnabled (cacheable = true)
    public static List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> fetchAllRecords(){
        try {
            list<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> lst = new list<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c>([select id,name from rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c order by Name]);
            return lst;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static string deleteObject(String removeObjectIds){
        try {
            List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> deleteObjectRecordList = new List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c>();
            system.debug('Id List-'+removeObjectIds);
           // if(String.isNotBlank(removeObjectIds)){
            // List<Id> objectIds = removeObjectIds.split(',');
            deleteObjectRecordList = [SELECT Id FROM rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c WHERE Id =: removeObjectIds];
            system.debug('Delete record list-'+deleteObjectRecordList);
       // }
        delete deleteObjectRecordList;
        updateSerialNumbers();
        return 'Setting updated Successfully!';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    private static void updateSerialNumbers() {
        List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> recordsToUpdate = new List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c>();
        
        // Query all records ordered by rbin__Record_No__c
        List<rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c> allRecords = [SELECT Id,Name, rbin__Record_No__c FROM rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c ORDER BY Name ASC];
        
        // Update the serial numbers
        Integer currentSerialNumber = 1;
        for (rbin__Recycle_Bin_Permnt_Delate_Tracking_Obj__c record : allRecords) {
            record.rbin__Record_No__c = currentSerialNumber++;
            recordsToUpdate.add(record);
        }
        
        // Perform the update
        update recordsToUpdate;
    }
}