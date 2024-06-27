@isTest
public class testpermanentDeletedRecordPreviewCtrl {

    @testSetup static void dataSetup() {
        Account accObj = new Account();
        accObj.Name = 'Demo Account 1';
        accObj.AnnualRevenue = 10000;
        accObj.BillingCity = 'Nagpur';
        accObj.BillingCountry = 'India';
        accObj.Rating = 'Hot';
        insert accObj;

        String recordData = JSON.serializePretty(accObj);

       rbin__Deleted_Data__c Deleted_DataObj = new rbin__Deleted_Data__c();
        Deleted_DataObj.rbin__Object_Name__c = 'Account';
        Deleted_DataObj.rbin__Record_ID__c = accObj.Id;
        Deleted_DataObj.rbin__Record_Name__c = 'Demo Account 1';
        Deleted_DataObj.rbin__Deleted_Date__c = system.now();
		insert Deleted_DataObj;
        
         ContentVersion cVersion = new ContentVersion();
            cVersion.ContentLocation = 'S';
            cVersion.PathOnClient = accObj.Id + '.txt';
            cVersion.Origin = 'H';
            cVersion.Title = accObj.Id;
            Blob body = Blob.valueOf(recordData);
            cVersion.VersionData = body;
        insert cVersion;
        
        ContentVersion cv = [SELECT Id, ContentDocumentId, Title FROM ContentVersion LIMIT 1];
        ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = cv.ContentDocumentId;
            cdl.LinkedEntityId = Deleted_DataObj.Id;
            cdl.ShareType = 'I';
            cdl.Visibility = 'AllUsers';
        insert cdl;

    }
    
    @isTest
    public static void showPreviewPageTest(){
        rbin__Deleted_Data__c deletedDataObj = [Select Id, rbin__Object_Name__c, rbin__Record_ID__c FROM rbin__Deleted_Data__c LIMIT 1];
        
        Test.startTest();
        permanentDeletedRecordPreviewController.wrpDeletedData wrapResult = permanentDeletedRecordPreviewController.showPreviewPage(deletedDataObj.rbin__Record_ID__c);
        Test.stopTest();
        System.assertEquals('Account', wrapResult.objectName, 'Success');
    }
     @isTest
    public static void restoreRecordTest(){
        rbin__Deleted_Data__c deletedDataObj = [Select Id, rbin__Object_Name__c, rbin__Record_ID__c FROM rbin__Deleted_Data__c LIMIT 1];
        
        Test.startTest();
        permanentDeletedRecordPreviewController.restoreRecord(deletedDataObj.rbin__Record_ID__c);
        Test.stopTest();
        List<Account> objAcc = [Select Id, Name FROM Account WHERE Name = :'Demo Account 1'];
        System.assertEquals(2, objAcc.size(), 'Success');
    }
}