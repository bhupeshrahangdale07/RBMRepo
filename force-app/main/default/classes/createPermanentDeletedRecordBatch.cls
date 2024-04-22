

/** 
 *  @description This class used to create Permanent Delete record based on scheduled batch everyday.
 * It creates only those which are deleted within in 24 hours.
 * Version#     Date                            Author                                  Description
 * --------------------------------------------------------------------------------------------------------------
 * 1.0         27-07-2023                       Kandisa Technologies                    Initial Version 1.0
 * --------------------------------------------------------------------------------------------------------------
 */

public class createPermanentDeletedRecordBatch Implements Database.Batchable<sobject>, Database.Stateful {

    public List<rbin__Track_Batch_Process__c> lstTrackBatchProcess = new List<rbin__Track_Batch_Process__c>();
    public Map<String, String> objectKeyFieldMap = new Map<String, String>();
    private Integer recordNo = 1;
    private String objectName;
    /**
     * @description constructor of the batch class
     * @param recNo - record Number
     */
    public createPermanentDeletedRecordBatch(Integer recNo) {
        this.recordNo = recNo;
    }
    /**
     * @description start method which will get all the records from recycle bin of selected object.
     * @param bc - BatchableContext
     * @return Database.QueryLocator - list of records
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        // Get Object Key field for Different Objects
        this.objectKeyFieldMap = UtilityCls.fetchObjectKeyFields();
        
        lstTrackBatchProcess = new List<rbin__Track_Batch_Process__c>([
            SELECT
            rbin__Last_Run_Batch_Time__c
            FROM rbin__Track_Batch_Process__c
            WHERE Name = :Label.Track_Batch_Process
        ]);

        // Getting a single object from track deleted object data
        List<rbin__Permanent_Deleted_Tracking_Object__c> lstTrackDeletedObjects = new List<rbin__Permanent_Deleted_Tracking_Object__c>([
            SELECT
                Id,
                Name,
                rbin__Record_No__c
            FROM rbin__Permanent_Deleted_Tracking_Object__c
            WHERE rbin__Record_No__c = :recordNo LIMIT 1
        ]);

        String objName = (String) lstTrackDeletedObjects[0].get('Name');
        objectName = objName;
        String myQuery = '';

        // Fetch object fields
        List<String> fieldNames = new List<String>(UtilityCls.fetchObjectFieldMap(objName).keySet());

        Organization org =[Select id,OrganizationType From Organization Limit 1];

        if (lstTrackBatchProcess.size() > 0 && lstTrackBatchProcess[0].Last_Run_Batch_Time__c != null) {
            DateTime lastRunBatch = lstTrackBatchProcess[0].rbin__Last_Run_Batch_Time__c;

            // if(org.OrganizationType == 'Developer Edition'){
            // Content Publication limtis are not avalaible to check for org. For Developer Edition the Content Publication limtis is 2500 hence added Limit of 2500 for Developer Edition in query. 
            // myQuery = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + objName + ' WHERE IsDeleted = true and LastModifiedDate > :lastRunBatch LIMIT 2500 ALL ROWS';

            // } else {

            // }
            myQuery = 'SELECT ' + String.join(fieldNames, ',') + ' FROM ' + objName + ' WHERE IsDeleted = true and LastModifiedDate > :lastRunBatch ALL ROWS';
        }
        return Database.getQueryLocator(myQuery);
    }

    /**
     * @description execute method which will create the records in Deleted Data object.
     * @param bc - Database.BatchableContext 
     * @param sObjectRecords - list Of records
     */
    public void execute(Database.BatchableContext bc, List<SObject> sObjectRecords) {
        String recordName;
        List<rbin__Deleted_Data__c> upsertToDeletedData = new List<rbin__Deleted_Data__c>();

        // Get a list of Ids from List
        Set<Id> sObjectRecordIds = new Set<Id>(new Map<Id, SObject>(sObjectRecords).keySet());

        // Map to store deleted record Id and all data in JSON form
        Map<String, String> mapRecordData = new Map<String, String>();

        // Set of Ids to perform delete operation on existing contentDocument records
        Set<String> setExistedRecordIds = new Set<String>();

        if (sObjectRecords.size() > 0) {

            //Map to store existing deleted record and its Id
            Map<String, rbin__Deleted_Data__c> existingDeletedDataMap = new Map<String, rbin__Deleted_Data__c>();

            // Fetch Existing Deleted Data
            for (rbin__Deleted_Data__c objDeletedData : [SELECT
                Id,
                rbin__Record_ID__c,
                rbin__Record_Name__c,
                rbin__Deleted_By__c,
                rbin__Object_Name__c,
                rbin__Deleted_Date__c
            FROM rbin__Deleted_Data__c
            WHERE rbin__Record_ID__c IN :sObjectRecordIds]) {
                existingDeletedDataMap.put(objDeletedData.rbin__Record_ID__c, objDeletedData);
            }

            for (SObject rec : sObjectRecords) {
                // Fetch/Assign new deleted record
                if (!existingDeletedDataMap.containsKey(rec.Id)) {
                    if (objectKeyFieldMap.containsKey(String.valueOf(rec.getSObjectType()))) {
                        recordName = (String) rec.get(objectKeyFieldMap.get(String.valueOf(rec.getSObjectType())));
                    } else {
                        recordName = (String) rec.get('Name');
                    }

                    rbin__Deleted_Data__c newObject = new rbin__Deleted_Data__c();
                    newObject.rbin__Record_ID__c = rec.Id;
                    newObject.rbin__Record_Name__c = recordName;
                    newObject.rbin__Deleted_By__c = (String) rec.get('LastModifiedById');
                    newObject.rbin__Object_Name__c = String.valueOf(rec.getSObjectType());
                    newObject.rbin__Deleted_Date__c = (DateTime) rec.get('LastModifiedDate');

                    // Add deleted record Id and all data in JSON form in the 'mapRecordData'
                    mapRecordData.put(rec.Id, JSON.serializePretty(rec));
                    setExistedRecordIds.add(rec.Id);

                    // Add new deleted record to the list
                    upsertToDeletedData.add(newObject);
                } else {
                    // Fetch existing deleted record
                    if (existingDeletedDataMap.containsKey(rec.Id)) {
                        rbin__Deleted_Data__c existDeletedDataObj = new rbin__Deleted_Data__c();

                        if (rec != null) {
                            if (objectKeyFieldMap.containsKey(String.valueOf(rec.getSObjectType()))) {
                                existDeletedDataObj.rbin__Record_Name__c = (String) rec.get(objectKeyFieldMap.get(String.valueOf(rec.getSObjectType())));
                            } else {
                                existDeletedDataObj.rbin__Record_Name__c = (String) rec.get('Name');
                            }
                            existDeletedDataObj.Id = existingDeletedDataMap.get(rec.Id).Id;
                            existDeletedDataObj.rbin__Deleted_Date__c = (DateTime) rec.get('LastModifiedDate');

                            // Add deleted record Id and all data in JSON form in the 'mapRecordData'
                            mapRecordData.put(rec.Id, JSON.serializePretty(rec));
                            setExistedRecordIds.add(rec.Id);
                        }

                        // Update the existing deleted record
                        upsertToDeletedData.add(existDeletedDataObj);
                    }
                }
            }
        }
        // Insert/Update Deleted Data
        Database.Upsert(upsertToDeletedData, false);

        UtilityCls.createFileAttachment(mapRecordData, setExistedRecordIds);
    }
     /**
     * @description finish method which will call the batch every time as per the record number
     * @param bc - Database.BatchableContex
     */
    public void finish(Database.BatchableContext bc) {
        // Get the count of tracked delete objects
        Integer countTPDObjects = Database.countQuery('SELECT Count() FROM rbin__Permanent_Deleted_Tracking_Object__c');
        this.recordNo++;
        
        if (this.recordNo <= countTPDObjects) {
            // run batch till complete all track Permanent Deleted Objects.
            createPermanentDeletedRecordBatch bt = new createPermanentDeletedRecordBatch(recordNo);
            Database.executeBatch(bt);
        } else {
            // Update the last batch run on Track Batch Process setting
            if (lstTrackBatchProcess.size() > 0) {
                rbin__Track_Batch_Process__c objTrackBatchProcess = lstTrackBatchProcess[0];
                objTrackBatchProcess.rbin__Last_Run_Batch_Time__c = System.now();
                Update objTrackBatchProcess;
            }
        }
    }
}