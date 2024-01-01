/*
// --------------------------------------------------------------------------------------------------------------

// This class is the controller apex class to support the trackPermanentlyDeletedDataTab LWC Component
// Version#     Date                            Author                                  Description
// --------------------------------------------------------------------------------------------------------------
// 1.0         08-09-2023                     Kandisa Technologies                    Initial Version 1.0
// --------------------------------------------------------------------------------------------------------------

*/
public with sharing class trackPermanentDeletedDataCtrl {
    
    // method to be called for getting all the object names as an option for selection
    @AuraEnabled(cacheable = true)
    public static Map<string, string> getAllObjectName() {
        Map<string, string> mapOfAllObj = new Map<string, string>();
        List<String> ignorsObjects = UtilityCls.objectsToIgnore();
            String endpoint = URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v48.0/sobjects/';
        
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
        
        for (Object o : ob){
            Map<String, Object> real = (Map<String, Object>)o;
            
            if ((Boolean)real.get('triggerable')) {
                if(!ignorsObjects.contains(String.valueOf(real.get('name')))) {

                    String objLabel = String.valueOf(real.get('label'));
                    String name = String.valueOf(real.get('name'));
                    SObjectType schemaType = Schema.getGlobalDescribe().get(String.valueOf(real.get('name')));
                    
                    if (schemaType != null) {
                        if (schemaType.getDescribe().isAccessible() && schemaType.getDescribe().isDeletable() && schemaType.getDescribe().isQueryable() && !schemaType.getDescribe().isCustomSetting() && schemaType.getDescribe().isCreateable()&& schemaType.getDescribe().getName() != 'rbin__Deleted_Data__c'&& schemaType.getDescribe().isUndeletable()) {
                            String label = String.valueOf(real.get('label'));
                            mapOfAllObj.put(name, label);
                        } 
                    }
                }
            }
        }
        return mapOfAllObj;
    }
    
    // this method will save the record to rbin__Permanent_Deleted_Tracking_Object__c custom setting
    @AuraEnabled
    public static string saveTrackingObject(List<rbin__Permanent_Deleted_Tracking_Object__c> objNameList) {
        try {
            List<rbin__Permanent_Deleted_Tracking_Object__c> prmntObjectTrackingList = new List<rbin__Permanent_Deleted_Tracking_Object__c>();
            Decimal nextSerialNumber;
            // Query for the maximum existing serial number
            List<AggregateResult> ar = [SELECT MAX(rbin__Record_No__c) maxRecordNo FROM rbin__Permanent_Deleted_Tracking_Object__c];
            
            Decimal maxSerialNumber = (Decimal)ar[0].get('maxRecordNo');
            if (maxSerialNumber != null) { 
                // Increment by 1 to get the next serial number
                nextSerialNumber = maxSerialNumber + 1;
            }else if (maxSerialNumber == null) {
                nextSerialNumber = 1;
            }
            
            Map<String, String> mapObjectNames = getAllObjectName();

            for (rbin__Permanent_Deleted_Tracking_Object__c objName : objNameList) {
                rbin__Permanent_Deleted_Tracking_Object__c prmntTrckObj = new rbin__Permanent_Deleted_Tracking_Object__c();
                prmntTrckObj.Name = objName.Name;
                // Set the calculated serial number
                prmntTrckObj.rbin__Record_No__c = nextSerialNumber++;
                prmntTrckObj.rbin__Label__c = mapObjectNames.get(objName.Name);
                prmntObjectTrackingList.add(prmntTrckObj);
                
            }
            insert prmntObjectTrackingList;

            return 'Setting has been updated successfully!';
            
        } catch (Exception e) {
            system.debug('Error in Line Number-'+e.getLineNumber());
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    // this method will fetch all the records present in rbin__Permanent_Deleted_Tracking_Object__c custom setting
    @AuraEnabled (cacheable = true)
    public static List<rbin__Permanent_Deleted_Tracking_Object__c> fetchAllRecords() {
        try {
            list<rbin__Permanent_Deleted_Tracking_Object__c> lst = new list<rbin__Permanent_Deleted_Tracking_Object__c>([Select id,name,rbin__Label__c from rbin__Permanent_Deleted_Tracking_Object__c order by Name]);
            return lst;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // this method will delete the record from rbin__Permanent_Deleted_Tracking_Object__c custom setting
    @AuraEnabled
    public static string deleteObject(String removeObjectIds) {
        try {
            List<rbin__Permanent_Deleted_Tracking_Object__c> deleteObjectRecordList = new List<rbin__Permanent_Deleted_Tracking_Object__c>();
            
            deleteObjectRecordList = [SELECT Id FROM rbin__Permanent_Deleted_Tracking_Object__c WHERE Id = :removeObjectIds];
            delete deleteObjectRecordList;
            
            updateSerialNumbers();
            
            return 'Setting has been updated successfully!';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // this method will update the serial numbers of the records
    public static void updateSerialNumbers() {
        List<rbin__Permanent_Deleted_Tracking_Object__c> recordsToUpdate = new List<rbin__Permanent_Deleted_Tracking_Object__c>();
        // Query all records ordered by rbin__Record_No__c
        List<rbin__Permanent_Deleted_Tracking_Object__c> allRecords = [SELECT Id,Name, rbin__Record_No__c FROM 	rbin__Permanent_Deleted_Tracking_Object__c ORDER BY Name ASC];

        // Update the serial numbers
        Integer currentSerialNumber = 1;
        for (rbin__Permanent_Deleted_Tracking_Object__c record : allRecords) {
            record.rbin__Record_No__c = currentSerialNumber++;
            recordsToUpdate.add(record);
        }
        // Perform the update
        update recordsToUpdate;
    }
}