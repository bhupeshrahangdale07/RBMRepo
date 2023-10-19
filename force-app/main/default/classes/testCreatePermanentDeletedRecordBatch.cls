@isTest
public class testCreatePermanentDeletedRecordBatch {
    
    public rbin__ObjectKeyField__mdt getCustomMetadataRecord(){
        rbin__ObjectKeyField__mdt ObjectKeyField = new rbin__ObjectKeyField__mdt();
        ObjectKeyField.MasterLabel = 'Case';
        ObjectKeyField.rbin__Field_Name__c = 'CaseNumber';
        return ObjectKeyField;
    }
    
    @isTest
    public static void createPermanentDeletedRecordBtcMethod(){
        // Create test data for rbin__Track_Batch_Process__c
        rbin__Track_Batch_Process__c trackBatchProcess = new rbin__Track_Batch_Process__c(
            Name = 'Track Permanent Deleted Data Batch', 
           rbin__Last_Run_Batch_Time__c= system.now()-10);
        insert trackBatchProcess;
        
        	rbin__Permanent_Deleted_Tracking_Object__c trackingObj1 = new 	rbin__Permanent_Deleted_Tracking_Object__c(
            Name = 'Account', 
            rbin__Record_No__c = 1);
        
        insert trackingObj1;
        
        	rbin__Permanent_Deleted_Tracking_Object__c trackingObj2 = new 	rbin__Permanent_Deleted_Tracking_Object__c(
            Name = 'Case', 
            rbin__Record_No__c = 2);
        
        insert trackingObj2;
        
        Account accObj1= new Account();
        accObj1.Name= 'Acc1';
        insert accObj1;
        delete accObj1;
        
        Case caseObj= new Case();
        caseObj.Subject= 'Test Case';
        insert caseObj;
        delete caseObj;
        
        Id recId;
        Account accObj2= new Account();
        accObj2.Name= 'Acc2';
        insert accObj2;
       
        
        Account lstAcc=[Select id, Name,LastModifiedDate from Account where Name =:'Acc2' Limit 1];
        
        system.debug('Last Modified Date-'+lstAcc.LastModifiedDate);
        rbin__Deleted_Data__c Deleted_DataObj= new rbin__Deleted_Data__c();
        Deleted_DataObj.rbin__Object_Name__c = 'Account';
        Deleted_DataObj.rbin__Record_ID__c = lstAcc.Id;
        Deleted_DataObj.rbin__Record_Name__c = 'Acc2';
        Deleted_DataObj.rbin__Deleted_Date__c= system.now();
        Deleted_DataObj.rbin__Data__c = '{"attributes" : {"type" : "Account","url" : "/services/data/v58.0/sobjects/Account/0011N00001HROJwQAP"},"Id" : "0011N00001HROJwQAP","IsDeleted" : true,"Name" : "Acc2"}';
        insert Deleted_DataObj;
        
        delete accObj2;
        
        Test.startTest();
        createPermanentDeletedRecordBatch batchInstance = new createPermanentDeletedRecordBatch(1);
        Database.executeBatch(batchInstance);
        Test.stopTest();
        
        List<rbin__Deleted_Data__c> deletedDataRecords = [SELECT Id FROM rbin__Deleted_Data__c];
        System.assertEquals(3, deletedDataRecords.size());
            }
}