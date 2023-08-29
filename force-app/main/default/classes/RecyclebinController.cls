/*
// --------------------------------------------------------------------------------------------------------------

// This class is the controller apex class to support the Recycle_Bin_Manager visualforce page
// Version#     Date                            Author                                  Description
// --------------------------------------------------------------------------------------------------------------
// 1.0         3-1-2018                     Kandisa Technologies                    Initial Version 1.0
// --------------------------------------------------------------------------------------------------------------

*/

global with sharing class RecyclebinController {
    
    //Local variables referenced in the page 
    public string strKeyword {get; set;}
    public string strFromDate {get; set;}
    public string strToDate {get; set;}
    public List<SelectOption> lstObjects {get;set;}
    public string strSelectedObject {get; set;}
    public string strSelectedUser {get; set;}
    public transient List<Sobject> lstAllDeletedObjects;
    public List<List<wrapResults>> lstwrapResults {get; set;}
    public List<wrapResults> listForBothSearch {get; set;}
    public boolean IsAdminUser {get; set;}
    public String searchquery;
    public String queryString;
    public integer recordcount {get; set;}
    public String strSearchIn { get; set; }
    private map<string,string> mapObjectNames = new map<string,string>();
    
    //Constructor method below
    public RecyclebinController(){
        strKeyword = '';
        strFromDate = '';
        strToDate = '';
        lstObjects = new List<SelectOption>();
        strSelectedObject = '';
        lstwrapResults = new List<List<wrapResults>>();
        listForBothSearch = new List<wrapResults>();
        strSelectedUser = '';
        recordcount = 0;
        CheckAdminUser();
        strSearchIn='RecycleBin';
        
        set<string>  setFieldName = new set<string>();
        setFieldName.add('name');
        for(rbin__ObjectKeyField__mdt o : [select id,MasterLabel,rbin__Field_Name__c from rbin__ObjectKeyField__mdt where id != null]){
            setFieldName.add(o.rbin__Field_Name__c.tolowercase());
        }
        
        Set<string> setSobject = new Set<string>();
        setSobject.add('Address');
        setSobject.add('Location');
        setSobject.add('AppAnalyticsQueryRequest');
        setSobject.add('ContactPointTypeConsent');
        setSobject.add('DataUseLegalBasis');
        setSobject.add('DataUsePurpose');
        setSobject.add('ExpressionFilter');
        setSobject.add('ExpressionFilterCriteria');
        setSobject.add('Image');
        
        lstObjects.add(new SelectOption('','--Default--'));
        for(Schema.SObjectType objSType: Schema.getGlobalDescribe().Values()){
            Map<String, Schema.SObjectField> objectFields = objSType.getDescribe().fields.getMap();
            Boolean blnfield = false;
            
            if(setSobject.Contains(string.valueof(objSType))){
                continue;
            }
            
            for(string s : setFieldName){
                if(objectFields.containskey(s)){
                    blnfield = true;
                }
            }
            
            if( (blnfield)  && objectFields.containskey('isdeleted') && objectFields.containskey('lastmodifieddate') && objSType.getDescribe().isAccessible() && objSType.getDescribe().isDeletable() && objSType.getDescribe().isQueryable() && !objSType.getDescribe().isCustomSetting()){
                if(lstObjects.size()<1000) 
                {
                    lstObjects.add(new SelectOption(objSType.getDescribe().getName(),objSType.getDescribe().getLabel()));
                    mapObjectNames.put(objSType.getDescribe().getName(),objSType.getDescribe().getLabel());
                }
            }
        }
        doSort(lstObjects);
        
        system.debug('**constructor method**'+Apexpages.CurrentPage().getParameters().get('Object'));
        
        if(Apexpages.CurrentPage().getParameters().get('Object')!=null)
            strSelectedObject = string.escapeSingleQuotes( string.valueof(Apexpages.CurrentPage().getParameters().get('Object')));
        
        if(Apexpages.CurrentPage().getParameters().get('Keyword')!=null)
            strKeyword = string.escapeSingleQuotes( string.valueof(Apexpages.CurrentPage().getParameters().get('Keyword')));
        
        if(Apexpages.CurrentPage().getParameters().get('FromDate')!=null)
            strFromDate = string.escapeSingleQuotes( string.valueof(Apexpages.CurrentPage().getParameters().get('FromDate')));
        
        if(Apexpages.CurrentPage().getParameters().get('ToDate')!=null)
            strToDate = string.escapeSingleQuotes( string.valueof(Apexpages.CurrentPage().getParameters().get('ToDate')));
        
        if(Apexpages.CurrentPage().getParameters().get('SelectedUser')!=null)
            strSelectedUser = string.escapeSingleQuotes( string.valueof(Apexpages.CurrentPage().getParameters().get('SelectedUser')));
        
        if(!String.isBlank(strSelectedObject))
        {
            SearchRecords();
        }
        
    }
    
    public List<SelectOption>  rowOptions = new List<SelectOption> ();
    public List<SelectOption> getRowOptions() {
        List<SelectOption> opts = new List<SelectOption>();
        SelectOption sopt1 = new SelectOption('RecycleBin','<span title="It allows search in the recycle bin.">Recycle Bin</span>');
        sopt1.setEscapeItem(false);
        opts.add(sopt1);
        SelectOption sopt2 = new SelectOption('PermanentDeletedData','<span title="It allows search in the Permanent Deleted Data.">Permanent Deleted Data</span>');
        sopt2.setEscapeItem(false);
        opts.add(sopt2);
        SelectOption sopt3 = new SelectOption('Both','<span title="The search results are returned along with Permanently Deleted Data and Recycle Bin.">Both</span>');
        sopt3.setEscapeItem(false);
        opts.add(sopt3);
        return opts;
    }
    
    //method to determine if the logged in user has modify all access permission
    public void CheckAdminUser(){
        IsAdminUser = false;       
        List<PermissionSetAssignment> lstPermissionSets = new List<PermissionSetAssignment>([
            SELECT 
            	AssigneeId 
            FROM PermissionSetAssignment 
            WHERE AssigneeId =: UserInfo.getUserId() 
            AND PermissionSet.PermissionsModifyAllData = true
        ]);
        
        if(lstPermissionSets.size() > 0) {
            IsAdminUser = true;
        }       
    }
    
    private List<Sobject> findAllSobjectList(string strSelectedObject){
        List<Sobject> lstSobject = new List<Sobject>();  
        
        try{
            searchquery = ''; 
            String recordname = 'Name';
            Map<string,string>  mapFieldName = new Map<string,string>();
            
            for(rbin__ObjectKeyField__mdt o : [select id,MasterLabel,rbin__Field_Name__c from rbin__ObjectKeyField__mdt where id != null]){
                mapFieldName.put(o.MasterLabel,o.rbin__Field_Name__c);
            }
            
            if(mapFieldName.containsKey(strSelectedObject)){
                recordname = mapFieldName.get(strSelectedObject);
            }
            
            rbin__Recycle_Bin_Setting__c rbinsetting = rbin__Recycle_Bin_Setting__c.getOrgDefaults();  
            
            string strobjectfields = 'Id';
            if(strSelectedObject == 'ContentDocument'){
                strobjectfields = 'Id,'+recordname+' , LastModifiedDate';
            }else{
                strobjectfields = 'Id,'+recordname+' , LastModifiedDate, LastModifiedBy.Name';
            }
            
            searchquery += 'select '+ String.EscapeSingleQuotes(strobjectfields) +'  from ' +string.escapeSingleQuotes(strSelectedObject)+' Where IsDeleted = true ';
            if(!rbinsetting.rbin__Search_Inactive_Users_in_Deleted_By__c){
                searchquery += ' and LastModifiedById not in(select id from user where isactive=false) ';
            }

            string strWhereParam = '';
            if(!string.IsBlank(strKeyword)) {
                Map <String, Schema.SObjectField> mapfields = Schema.getGlobalDescribe().get(strSelectedObject).getDescribe().fields.getMap();
                
                strWhereParam = ' ( ';
                for(Schema.SObjectField sfield : mapfields.Values()){
                    Schema.DescribefieldResult dfield = Sfield.getDescribe();

                    if(dfield.getType() == Schema.DisplayType.String || dfield.getType() == Schema.DisplayType.Combobox) {
                        if(strWhereParam.length() > 3) {
                            strWhereParam += ' OR ';
                        }
                        string strValue = '%' + string.escapeSingleQuotes(strKeyword) + '%';
                        strWhereParam += string.escapeSingleQuotes(dfield.getName()) + ' like: strValue ';
                    }
                }
                strWhereParam += ' ) ';
            }
            
            if(!string.IsBlank(strFromDate)){
                Date dtFromDate = Date.NewInstance(Integer.valueof(strFromDate.split('/')[2]),Integer.valueof(strFromDate.split('/')[0]),Integer.valueof(strFromDate.split('/')[1]));
                if(strWhereParam.length() > 0) strWhereParam += ' and ';
                strWhereParam += ' Day_Only(LastModifiedDate) >=: dtFromDate';  
            }
            
            if(!string.IsBlank(strToDate)){
                Date dtToDate = Date.NewInstance(Integer.valueof(strToDate.split('/')[2]),Integer.valueof(strToDate.split('/')[0]),Integer.valueof(strToDate.split('/')[1]));
                if(strWhereParam.length() > 0) strWhereParam += ' and ';
                strWhereParam += ' Day_Only(LastModifiedDate) <=: dtToDate';  
            }
            
            if(!IsAdminUser) {
                if(strWhereParam.length() > 0) strWhereParam += ' and ';
                string loggedinuserid = UserInfo.getUserId();
                strWhereParam += ' LastModifiedById =:loggedinuserid '  ;  
            } 
            else if(!string.IsBlank(strSelectedUser)){
                string userid = strSelectedUser;
                if(strWhereParam.length() > 0) strWhereParam += ' and ';
                strWhereParam += ' LastModifiedById =: userid ' ;  
            }
            
            if(strWhereParam.length() > 0) searchquery += ' and ';
            searchquery += string.escapeSingleQuotes(strWhereParam) + ' order by LastModifiedDate desc LIMIT '+integer.valueof(System.label.Row_Count_Limit) +' ALL ROWS ';
            
            if(!string.IsBlank(searchquery)) {
                List<SObject> searchList;
                searchList = Database.query(String.EscapeSingleQuotes(searchquery));
                lstSobject.addall(searchList);
            }
        }catch(Exception ex){
            return null;
        }
        return lstSobject;
    }
    
    public void searchInRecycleBin(){
        Map<string,string>  mapFieldName = new Map<string,string>();
        
        for(rbin__ObjectKeyField__mdt o : [select id,MasterLabel,rbin__Field_Name__c from rbin__ObjectKeyField__mdt where id != null]){
            mapFieldName.put(o.MasterLabel,o.rbin__Field_Name__c);
        }
        
        lstAllDeletedObjects = new List<Sobject>();
        lstwrapResults = new List<List<wrapResults>>();
        listForBothSearch = new List<wrapResults>();
        
        List<rbin__RecycleSearchObjects__c> lstCustomSettings = rbin__RecycleSearchObjects__c.getall().values();
        Integer intLimit = 0;
        
        if(!string.isblank(strFromDate) && !string.isblank(strToDate)){
            Date dtFromDate = Date.NewInstance(Integer.valueof(strFromDate.split('/')[2]),Integer.valueof(strFromDate.split('/')[0]),Integer.valueof(strFromDate.split('/')[1]));
            Date dtToDate = Date.NewInstance(Integer.valueof(strToDate.split('/')[2]),Integer.valueof(strToDate.split('/')[0]),Integer.valueof(strToDate.split('/')[1]));
            
            if(dtFromDate > dtToDate){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,' Deleted From Date cannot be greater than Deleted To Date.'));
                return;
            }
        }
        
        List<Sobject> lstSobjecttemp = new List<Sobject>();   
        if(string.IsBlank(strSelectedObject)) {
            
            for(rbin__RecycleSearchObjects__c o : lstCustomSettings){
                if(intLimit == 20) break;

                lstSobjecttemp = findAllSobjectList(o.Name);
                if(lstSobjecttemp != null && lstSobjecttemp.size()>0)
                    lstAllDeletedObjects.addAll(lstSobjecttemp);              
                intLimit++;
            }
        }else{
            lstSobjecttemp = findAllSobjectList(strSelectedObject);
            
            if(lstSobjecttemp == null){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, ' Salesforce currently doesn\'t support restoring  records of the ' + strSelectedObject + ' Object.'));
                return;
            }
            lstAllDeletedObjects.addAll(lstSobjecttemp);
        }
        
        if(lstAllDeletedObjects.size() > 0) {
            Integer count = 0;
            List<wrapResults> lsttempWrap = new List<wrapResults>();
            recordcount = lstAllDeletedObjects.size();
            
            Set<Id> ContentDocumentIds = new Set<Id>();
            for (SObject objs : lstAllDeletedObjects) {
                string strobjecttype =  string.valueof(objS.getSObjectType());
                if(strobjecttype == 'ContentDocument'){
                    ContentDocumentIds.add((Id)objS.get('Id'));
                }
            }
            
            Map<Id,String> mapContentDocumentDeletedBy = new Map<Id,String>();
            for (ContentVersion cv : [SELECT Id,LastModifiedById,LastModifiedBy.Name,ContentDocumentId FROM ContentVersion where ContentDocumentId in: ContentDocumentIds and ContentDocument.IsDeleted = true ALL ROWS]) {
                mapContentDocumentDeletedBy.put(cv.ContentDocumentId,cv.LastModifiedBy.Name);
            }
            
            for(SObject objS: lstAllDeletedObjects){
                
                string strobjecttype =  string.valueof(objS.getSObjectType());
                wrapResults objW = new wrapResults();
                objW.Id = string.valueof(objS.get('Id'));
                
                if(mapFieldName.containsKey(strobjecttype)){
                    objW.Name = string.valueof(objS.get(mapFieldName.get(strobjecttype)));
                }
                else{
                    objW.Name = string.valueof(objS.get('Name'));
                }     
                
                objW.SObjectAPIName = strobjecttype;
                if(mapObjectNames.containskey(strobjecttype)) {
                    objW.Type = mapObjectNames.get(strobjecttype);
                } else {
                    objW.Type = strobjecttype;
                }
                
                if(objW.SObjectAPIName == 'ContentDocument'){
                    if(mapContentDocumentDeletedBy.containsKey(objW.Id)){
                        objW.DeletedBy = mapContentDocumentDeletedBy.get(objW.Id);
                    }
                }else{
                    Sobject objR = objS.getSObject('LastModifiedBy');
                    objW.DeletedBy = string.valueof(objR.get('Name'));
                }
                
                objW.DeletedOn = DateTime.valueof(objS.get('LastModifiedDate')).format('MM/dd/yyyy hh:mm a');
                if(count == 1000) {
                    lstwrapResults.add(lsttempWrap);
                    lsttempWrap = new List<wrapResults>();
                    count = 0;
                
                }
                lsttempWrap.add(objW);
                listForBothSearch.add(objw);
                count++;
            }
            
            if(lsttempWrap.size() > 0) {
                lstwrapResults.add(lsttempWrap);
               
                
            }  
        }
    }
    
    public void searchInPermanentlyDeletedData(){
        
        lstwrapResults = new List<List<wrapResults>>();
        
        if(!string.isblank(strFromDate) && !string.isblank(strToDate)){
            Date dtFromDate = Date.NewInstance(Integer.valueof(strFromDate.split('/')[2]),Integer.valueof(strFromDate.split('/')[0]),Integer.valueof(strFromDate.split('/')[1]));
            Date dtToDate = Date.NewInstance(Integer.valueof(strToDate.split('/')[2]),Integer.valueof(strToDate.split('/')[0]),Integer.valueof(strToDate.split('/')[1]));
            if(dtFromDate > dtToDate){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,' Deleted From Date cannot be greater than Deleted To Date.'));
                return;
            }
        }
        
        if(Apexpages.CurrentPage().getParameters().get('Keyword')!=null)
            strKeyword = string.escapeSingleQuotes( string.valueof(Apexpages.CurrentPage().getParameters().get('Keyword')));

        if(Apexpages.CurrentPage().getParameters().get('Object')!=null)
            strSelectedObject = string.escapeSingleQuotes( string.valueof(Apexpages.CurrentPage().getParameters().get('Object')));
        
        String searchKey= '%'+strKeyword+'%';
        
        String queryString = 'SELECT Id, Name, rbin__Record_ID__c, rbin__Object_Name__c, rbin__Deleted_By__r.Name, rbin__Record_Name__c, rbin__Deleted_Date__c ' +
            'FROM rbin__Deleted_Data__c WHERE Id !=null';
        
        if (strSelectedObject != null) {
            queryString += ' AND rbin__Object_Name__c = :strSelectedObject';
        }
        
        if (searchKey != null) {
            queryString += ' AND rbin__Record_Name__c LIKE :searchKey';
        }
        
        if (!string.isblank(strFromDate)) {
            Date dtFromDate = Date.NewInstance(Integer.valueof(strFromDate.split('/')[2]),Integer.valueof(strFromDate.split('/')[0]),Integer.valueof(strFromDate.split('/')[1]));
            queryString += ' AND DAY_ONLY(rbin__Deleted_Date__c) > :dtFromDate';
        }
        
        if (!string.isblank(strToDate)) {
            Date dtToDate = Date.NewInstance(Integer.valueof(strToDate.split('/')[2]),Integer.valueof(strToDate.split('/')[0]),Integer.valueof(strToDate.split('/')[1]));
            queryString += ' AND DAY_ONLY(rbin__Deleted_Date__c) < :dtToDate';
        }
        
        if (!string.IsBlank(strSelectedUser)){
            queryString += ' AND rbin__Deleted_By__c =: strSelectedUser';
        }
        
        List<rbin__Deleted_Data__c> permanentDeletedDataList = Database.query(queryString);
        List<wrapResults> lsttempWrap = new List<wrapResults>();
        
        for (rbin__Deleted_Data__c pdd : permanentDeletedDataList) {
        
            wrapResults objW = new wrapResults();
            // Assign the field values directly to wrapper class properties
            objW.Id = pdd.rbin__Record_ID__c != null ? string.valueof(pdd.rbin__Record_ID__c) : '';
            objW.Name = pdd.rbin__Record_Name__c != null ? string.valueof(pdd.rbin__Record_Name__c) : '';
            objW.SObjectAPIName = pdd.rbin__Object_Name__c != null ? pdd.rbin__Object_Name__c : '';
            objW.Type = pdd.rbin__Object_Name__c != null ? pdd.rbin__Object_Name__c : '';
            objW.DeletedBy = pdd.rbin__Deleted_By__c != null && pdd.rbin__Deleted_By__r.Name != null ? string.valueof(pdd.rbin__Deleted_By__r.Name) : '';
            objW.DeletedOn = pdd.rbin__Deleted_Date__c != null ? DateTime.valueof(pdd.rbin__Deleted_Date__c).format('MM/dd/yyyy hh:mm a') : '';
            objw.isPermanentlyDeleted = 'Yes';
            
            // Add the populated wrapper object to the list
            lsttempWrap.add(objW);
        }
        
        lstwrapResults.add(lsttempWrap);
    }
    
    //method to search the deleted records based on the search critiera specified by the user
    public void SearchRecords(){
        try {

            if(this.strSearchIn == 'RecycleBin'){
                searchInRecycleBin();
                listForBothSearch=null;
                
            } else  if(strSearchIn == 'PermanentDeletedData'){
                searchInPermanentlyDeletedData();
                listForBothSearch=null;
                
            }else if(strSearchIn == 'Both'){
                lstwrapResults = new List<List<wrapResults>>();
                listForBothSearch = new List<wrapResults>();
                searchInRecycleBin();
                searchInPermanentlyDeletedData();
                lstwrapResults.add(listForBothSearch);
            }
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
        }
    }
    
    //method to clear the pre-selected filters 
    public void Clear(){
        strKeyword = '';
        strFromDate = '';
        strToDate = '';
        strSelectedObject = '';
        strSelectedUser = '';
        lstAllDeletedObjects = new List<Sobject>();
        lstwrapResults = new List<List<wrapResults>>();
    }
    
    //Remote action method to get Users
    @RemoteAction
    global static List<User> queryUsers(String keyword) {
        List<User> userlist = new List<User>();
        if (keyword != null && keyword.trim() != '') {
            keyword = '%' + keyword + '%';
            if(Schema.sObjectType.User.isAccessible()) {
                userlist = [Select Id, Name, Email from User where Name like :keyword and Profile.UserLicense.Name != 'Chatter Free' Order By Name limit 5];   
            }
        }
        return userlist;
    }
    
    //method to restore the selected records
    public void UndeleteSelectedRecords(){
        try {
            List<Sobject> lstSobjecttoUndelete = new List<Sobject>();
            for(List<wrapResults> lstWrapper: lstwrapResults){
                for(wrapResults objW: lstWrapper) {
                    if(objW.isCheck) {
                        Sobject objS = Schema.getGlobalDescribe().get(objW.SObjectAPIName).newSObject();
                        objS.Put('Id',objW.Id);
                        lstSobjecttoUndelete.add(objS);
                    }
                }
            }
            if(lstSobjecttoUndelete.size() > 0) {
                Database.UndeleteResult[] undeleteresult = Database.Undelete(lstSobjecttoUndelete, false);
                
                Integer successcount = 0;
                Integer failcount = 0;
                for(Database.UndeleteResult result: undeleteresult){
                    if(result.isSuccess()){
                        successcount++;
                    } else {
                        system.debug('**'+result.getErrors());
                        failcount++;
                    }
                }
                //undelete lstSobjecttoUndelete;
                if(successcount > 0) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm, ' '+successcount + ' selected record(s) have been restored successfully.',''));
                }
                if(failcount > 0) {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, ' '+failcount + ' selected record(s) are in process of getting purged.',''));
                } 
                SearchRecords();
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,' Please select at least one record to undelete.',''));
            }
        } catch (Exception ex) {
            if(ex.getmessage().contains('Entity is not in the recycle bin')){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,' Entity is not in the recycle bin.',''));
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,' Salesforce runs a process on a scheduled basis that physically deletes records that have been deleted from the recycle bin, if that process has not run yet, you will still see the records here.',''));
            } else {
                ApexPages.addMessages(ex);
            }
            return;
        }
    }
    
    //method to restore all the records returned by the serach query
    public void UndeleteAllRecords(){
        try {
            if(lstwrapResults.size() > 0){
                List<Sobject> lstUndeleteAll = new List<Sobject>();
                //lstwrapResults is list of list of 1000 records. if size is > 1 means it have more than 1000 records.
            
                //added by RP on 22-11-2018
                if(lstwrapResults.size() > 1) {
                    List<string> lstUndeleteAllRecords = new List<string>();
                    string strval = '';
                    for(List<wrapResults> lstWrapper: lstwrapResults){
                        for(wrapResults objW: lstWrapper) {
                            strval = '';
                            strval = string.valueof(objW.SObjectAPIName)+'#'+string.valueof(objW.Id);
                            lstUndeleteAllRecords.add(strval);
                        }
                    }
                    BatchMassUndeleteRecords batchtoundelete = new BatchMassUndeleteRecords(lstUndeleteAllRecords);
                    Database.executeBatch(batchtoundelete, 20);
                    
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,' A Batch process has been scheduled to restore the records. You may check the batch job status by clicking on the Mass Restore Batch Status tab.',''));
                    return;
                }
                
                for(List<wrapResults> lstWrapper: lstwrapResults){
                    for(wrapResults objW: lstWrapper) {
                        Sobject objS = Schema.getGlobalDescribe().get(objW.SObjectAPIName).newSObject();
                        objS.Put('Id',objW.Id);
                        lstUndeleteAll.add(objS);
                    }
                }
                if(lstUndeleteAll.size() > 0) {
                    Database.UndeleteResult[] undeleteresult = Database.Undelete(lstUndeleteAll,false);
                    //undelete lstUndeleteAll;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,' All records have been restored successfully.',''));
                    SearchRecords();
                }
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,' Please select at least one record to undelete.',''));
            }
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
            return;
        }
    }
    
    
    //method to purge the selected records from the recycle bin
    public void DeleteFromRecyclebin(){
        try {
            List<Id> lstIdstoDelete = new List<Id>();
            for(List<wrapResults> lstWrapper: lstwrapResults){
                for(wrapResults objW: lstWrapper) {
                    if(objW.isCheck) {
                        lstIdstoDelete.add(objW.Id);
                    }
                }
            } 
            if(lstIdstoDelete.size() > 0) {
                Database.EmptyRecyclebin(lstIdstoDelete);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Confirm,' Selected records have been deleted successfully.',''));
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Warning,' Salesforce runs a process on a scheduled basis that physically deletes records that have been deleted from the recycle bin, if that process has not run yet, you will still see the records here.',''));
                
            } else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,' Please select at least one record.',''));
            }
            SearchRecords();
        } catch (Exception ex) {
            ApexPages.addMessages(ex);
            return;
        }
    }
    
    //wrapper class
    public class wrapResults {
        public boolean isCheck {get; set;}
        public string Id {get; set;}
        public string Name {get; set;}
        public string Type {get; set;}
        public string SObjectAPIName {get; set;}
        public string DeletedBy {get; set;}
        public string DeletedOn {get; set;}
        public string isPermanentlyDeleted {get; set;}
        public wrapResults(){
            isCheck = false;
            isPermanentlyDeleted = 'No';
            Id = '';
            Name = '';
            SObjectAPIName = '';
            Type = '';
            DeletedBy = '';
            DeletedOn = '';
        }
    }
    
    //method to sort the data
    public static void doSort(List<Selectoption> opts) {
        
        Map<String, Selectoption> mapping = new Map<String, Selectoption>();
        // Suffix to avoid duplicate values like same labels or values are in inbound list 
        Integer suffix = 1;
        for (Selectoption opt : opts) {
            mapping.put(    // Done this cryptic to save scriptlines, if this loop executes 10000 times
                // it would every script statement would add 1, so 3 would lead to 30000.
                (opt.getLabel() + suffix++), // Key using Label + Suffix Counter  
                opt);    
        }
        
        List<String> sortKeys = new List<String>();
        sortKeys.addAll(mapping.keySet());
        sortKeys.sort();
        // clear the original collection to rebuilt it
        opts.clear();
        
        for (String key : sortKeys) {
            opts.add(mapping.get(key));
        }
    }
}