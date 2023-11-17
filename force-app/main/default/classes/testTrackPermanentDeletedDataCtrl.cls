@isTest
public class testTrackPermanentDeletedDataCtrl {

    @testSetup static void testDataSetup() {
        rbin__Permanent_Deleted_Tracking_Object__c trackingObject1 = new rbin__Permanent_Deleted_Tracking_Object__c();
        trackingObject1.Name = 'Account';
        trackingObject1.rbin__Record_No__c = 1;
        insert trackingObject1;
        
        rbin__Permanent_Deleted_Tracking_Object__c trackingObject2 = new rbin__Permanent_Deleted_Tracking_Object__c();
        trackingObject2.Name = 'Contact';
        trackingObject2.rbin__Record_No__c = 2;
        insert trackingObject2;
    }

 	@isTest
    public static void getAllObjectNameTest(){
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new createApexTriggerMock());
        Map<string, string> mapOfAllObj = trackPermanentDeletedDataCtrl.getAllObjectName();
        Test.stopTest();
        System.assertEquals(true, mapOfAllObj.containsKey('Account'), 'Account should be in the result');
    }
    @isTest
    public static void saveTrackingObjectTest(){
        
        List<rbin__Permanent_Deleted_Tracking_Object__c> lstTrackingObj =[Select Id, Name FROM rbin__Permanent_Deleted_Tracking_Object__c];
        Test.startTest();
        String response = trackPermanentDeletedDataCtrl.saveTrackingObject(lstTrackingObj);
        Test.stopTest();
        
        System.assertEquals('Setting Updated Successfully!', response, 'Success');
    }
    @isTest
    public static void fetchAllRecordsTest(){
        
        Test.startTest();
        List<rbin__Permanent_Deleted_Tracking_Object__c> lstRecords = trackPermanentDeletedDataCtrl.fetchAllRecords();
        Test.stopTest();
        System.assertEquals(false, lstRecords.isEmpty(), 'Success');
    }
    @isTest
    public static void deleteObjectTest(){
        
        rbin__Permanent_Deleted_Tracking_Object__c lstTrackingObj =[Select Id, Name FROM rbin__Permanent_Deleted_Tracking_Object__c LIMIT 1];
        Test.startTest();
        String response = trackPermanentDeletedDataCtrl.deleteObject(lstTrackingObj.Id);
        Test.stopTest();
        System.assertEquals('Setting updated Successfully!', response, 'Success');
    }
    @isTest
    public static void updateSerialNumbersTest(){

        Test.startTest();
        trackPermanentDeletedDataCtrl.updateSerialNumbers();
        Test.stopTest();
        List<rbin__Permanent_Deleted_Tracking_Object__c> updatedRecords = [SELECT Id, Name, rbin__Record_No__c FROM rbin__Permanent_Deleted_Tracking_Object__c ORDER BY Name ASC];
        
        Integer expectedSerialNumber = 1;
        for (rbin__Permanent_Deleted_Tracking_Object__c record : updatedRecords) {
            System.assertEquals(expectedSerialNumber, record.rbin__Record_No__c);
            expectedSerialNumber++;
        }
        
    }
}