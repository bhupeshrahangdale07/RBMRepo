/*
// --------------------------------------------------------------------------------------------------------------

// This class is the controller apex class to support the Recycle_Bin_Manager visualforce page
// Version#     Date                            Author                                  Description
// --------------------------------------------------------------------------------------------------------------
//           11/9/2018                     Kandisa Technologies                    
// --------------------------------------------------------------------------------------------------------------

*/

global with sharing class SearchObjectSetting {
    global List<SelectOption> lstObjects {get;set;}
    global static List<SelectOption> lsttrackingObjects {get;set;}
    global static String Host {get;set;}
    global static String remotesiteurl {get;set;}
    global static String orginstance {get;set;}
    global static List<trackingobject> lst = new List<trackingobject>();
    global String endpoint = System.URL.getSalesforceBaseUrl().toExternalForm() + '/services/data/v48.0/tooling/sobjects';
    
    global SearchObjectSetting(){
        Host = System.URL.getSalesforceBaseUrl().toExternalForm() + '/services/Soap/m/31.0';
        remotesiteurl = System.URL.getSalesforceBaseUrl().toExternalForm();
        orginstance = System.URL.getOrgDomainUrl().toExternalForm();
        lstObjects = new List<SelectOption>();
        lstObjects = fnBindsObject();
        RecyclebinController.doSort(lstObjects);
    }
    
    global List<wrapperforweek> getweeklist {
        get {
            List<wrapperforweek> options = new List<wrapperforweek>();
            options.add(new wrapperforweek(1, 'Sunday'));
            options.add(new wrapperforweek(2, 'Monday'));
            options.add(new wrapperforweek(3, 'Tuesday'));
            options.add(new wrapperforweek(4, 'Wednesday'));
            options.add(new wrapperforweek(5, 'Thursday'));
            options.add(new wrapperforweek(6, 'Friday'));
            options.add(new wrapperforweek(7, 'Saturday'));
            return options;
        }  
        set;
    }
    
    global List<SelectOption> getpreferedtime {
        get {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('0', '12:00 AM'));
            options.add(new SelectOption('1', '1:00 AM'));
            options.add(new SelectOption('2', '2:00 AM'));
            options.add(new SelectOption('3', '3:00 AM'));
            options.add(new SelectOption('4', '4:00 AM'));
            options.add(new SelectOption('5', '5:00 AM'));
            options.add(new SelectOption('6', '6:00 AM'));
            options.add(new SelectOption('7', '7:00 AM'));
            options.add(new SelectOption('8', '8:00 AM'));
            options.add(new SelectOption('9', '9:00 AM'));
            options.add(new SelectOption('10', '10:00 AM'));
            options.add(new SelectOption('11', '11:00 AM'));
            options.add(new SelectOption('12', '12:00 PM'));
            options.add(new SelectOption('13', '1:00 PM'));
            options.add(new SelectOption('14', '2:00 PM'));
            options.add(new SelectOption('15', '3:00 PM'));
            options.add(new SelectOption('16', '4:00 PM'));
            options.add(new SelectOption('17', '5:00 PM'));
            options.add(new SelectOption('18', '6:00 PM'));
            options.add(new SelectOption('19', '7:00 PM'));
            options.add(new SelectOption('20', '8:00 PM'));
            options.add(new SelectOption('21', '9:00 PM'));
            options.add(new SelectOption('22', '10:00 PM'));
            options.add(new SelectOption('23', '11:00 PM'));
            return options;
        }  
        set;
    }
    
    global List<SelectOption> fnBindsObject(){
        List<SelectOption> lst = new List<SelectOption>();
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
        
        //lstObjects.add(new SelectOption('','--Default--'));
        for(Schema.SObjectType objSType: Schema.getGlobalDescribe().Values()){
            try{
                Map<String, Schema.SObjectField> objectFields = objSType.getDescribe().fields.getMap();
                
                if(setSobject.Contains(string.valueof(objSType))){
                    continue;
                }
                
                Boolean blnfield = false;
                for(string s : setFieldName){
                    if(objectFields.containskey(s)){
                        blnfield = true;
                    }
                }
                
                if( (blnfield)  && objectFields.containskey('isdeleted') && objectFields.containskey('lastmodifieddate') && objSType.getDescribe().isAccessible() && objSType.getDescribe().isDeletable() && objSType.getDescribe().isQueryable() && !objSType.getDescribe().isCustomSetting() && !objSType.getDescribe().getName().containsignorecase('feed') && objSType.getDescribe().isQueryable()){
                    if(lst.size()<1000) 
                    {
                        lst.add(new SelectOption(objSType.getDescribe().getName(),objSType.getDescribe().getLabel()));                    
                    }
                }
            }catch(Exception e) { system.debug('@@@exception@@@ '); }
        }
        return lst;        
    }
    
    @RemoteAction
    global static List<trackingobject> triggerableobjects(){
        if(lst.size() == 0){
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
                        trackingobject trackobj = new trackingobject();
                        trackobj.name = String.valueOf(real.get('label'));
                        trackobj.value = String.valueOf(real.get('name'));
                        SObjectType schemaType = Schema.getGlobalDescribe().get(String.valueOf(real.get('name')));
                        if(schemaType.getDescribe().isAccessible() && schemaType.getDescribe().isDeletable() && schemaType.getDescribe().isQueryable() && !schemaType.getDescribe().isCustomSetting()) {
                            lst.add(trackobj);   
                        }
                    }
                }
            }
        } 
        return lst;
    }
    
    //method to sort the data
    global void doSort(List<Selectoption> opts) {
        
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
    
    @RemoteAction //the function to be called in remote action and used to get all existing custom setting records
    global static Map<string,string> getAllObjects() { 
        set<string>  setFieldName = new set<string>();
        setFieldName.add('name');
        for(rbin__ObjectKeyField__mdt o : [select id,MasterLabel,rbin__Field_Name__c from rbin__ObjectKeyField__mdt]){
            setFieldName.add(o.rbin__Field_Name__c.tolowercase());
        }
        
        Map<string,string> mapObjects = new Map<string,string>();
        for(Schema.SObjectType objSType: Schema.getGlobalDescribe().Values()){
            
            Map<String, Schema.SObjectField> objectFields = objSType.getDescribe().fields.getMap();
            //system.debug('@@@objSType ' + objSType.getDescribe());
            
            Boolean blnfield = false;
            for(string s : setFieldName){
                if(objectFields.containskey(s)){
                    blnfield = true;
                }
            }
            
            
            if( ( blnfield )  && objectFields.containskey('isdeleted') && objectFields.containskey('lastmodifieddate') && objSType.getDescribe().isAccessible() && objSType.getDescribe().isDeletable() && objSType.getDescribe().isQueryable() && !objSType.getDescribe().isCustomSetting()){
                //if(mapObjectVsAllowLayout.containsKey(objSType.getDescribe().getName()) && mapObjectVsAllowLayout.get(objSType.getDescribe().getName())){
                mapObjects.put(objSType.getDescribe().getName(),objSType.getDescribe().getLabel());                                       
                //}                   
            }
        }        
        return mapObjects;
    }
    
    @RemoteAction //the function to be called in remote action and used to get all existing custom setting records
    global static list<rbin__RecycleSearchObjects__c> findSearchExistingRecords() { 
        list<rbin__RecycleSearchObjects__c> lst = new list<rbin__RecycleSearchObjects__c>([select id,name from rbin__RecycleSearchObjects__c order by Name]);
        return lst;
    }
    
    @RemoteAction //the function to be called in remote action and used to get all existing custom setting records
    global static list<rbin__Recycle_Bin_Tracking_Objects__c> findTrackingExistingRecords() { 
        list<rbin__Recycle_Bin_Tracking_Objects__c> lst = new list<rbin__Recycle_Bin_Tracking_Objects__c>([select id,name from rbin__Recycle_Bin_Tracking_Objects__c order by Name]);
        return lst;
    }
    
    @RemoteAction //the function to be called in remote action and used to get all existing custom setting records
    global static boolean save(list<rbin__RecycleSearchObjects__c> lst) {   
        //system.debug('@@@@@@save ' + lst) ;
        upsert lst;
        return true;
    }
    
    @RemoteAction //the function to be called in remote action and used to get all existing custom setting records
    global static boolean savetrackingobjects(list<rbin__Recycle_Bin_Tracking_Objects__c> lst) {  
        List<rbin__Recycle_Bin_Setting__c> rbinsetting = new List<rbin__Recycle_Bin_Setting__c>{rbin__Recycle_Bin_Setting__c.getOrgDefaults()};    
            
            upsert lst;
        
        if(rbinsetting.size() > 0 && rbinsetting[0].rbin__Real_time_object_tracking__c){
            createtriggerfortrackedobject();
        }
        
        return true;
    }
    
    global void createApexClass(String objName)
    { 
        // create a Http request with post method
        HttpRequest req = createHttpRequest(endpoint+'/ApexTrigger','POST');
        req.setBody( '{"Name":"NewApexTrigger1","TableEnumOrId": "'+objName+'" ,"Body":"trigger rbin'+(objName.contains('__c') ? objName.removeEnd('__c').remove('_') + 'Trigger' : objName+'Trigger' )+' on ' + objName + ' (after delete) { \\n if (Trigger.isDelete && Trigger.isAfter) {\\n rbin.SendMailForTrackingObject.sendmailwhenrecdelete(Trigger.old);  \\n} \\n}"}');
        // send request and receive response
        String response = getResponse(req);
        system.debug('response ' + response);
    }
    
    global static void createbatchscheduleclass(){
        String sch = '';
        List<rbin__Recycle_Bin_Setting__c> rbinsetting = new List<rbin__Recycle_Bin_Setting__c>{rbin__Recycle_Bin_Setting__c.getOrgDefaults()};
            
            /*if(rbinsetting.size() > 0 && rbinsetting[0].rbin__Schedule_object_tracking__c) {
                rbin.scheduletrackingobjbatch schbatch = new rbin.scheduletrackingobjbatch();
                if(rbinsetting[0].rbin__isDaily__c){
                    sch = '0 0 ' + rbinsetting[0].rbin__Preferred_Start_Time__c + ' ? * *';
                } 
                else if(rbinsetting[0].rbin__isWeekly__c) {
                    sch = '0 0 ' + rbinsetting[0].rbin__Preferred_Start_Time__c + ' ? * ' + rbinsetting[0].rbin__SelectedWeek__c;
                }
                
                List<CronJobDetail> crondetail = [Select Id, Name From CronJobDetail where Name = 'schedule bacth apex'];
                if(crondetail.size() > 0) {
                    List<CronTrigger> crontri = [Select Id,CronJobDetailId,CronExpression from CronTrigger where CronJobDetailId = :crondetail[0].Id];
                    if(crontri.size() > 0) {
                        if(crontri[0].CronExpression != sch) {
                            deletescheduledjob();
                            system.schedule('schedule bacth apex', sch, schbatch);
                        } 
                    }
                } else {
                    system.schedule('schedule bacth apex', sch, schbatch);
                }
            }*/
    }
    
    // create a http request with required endpoint and request method
    global HttpRequest createHttpRequest(String endpoint, String method)
    {
        HttpRequest req = new
            HttpRequest();
        endpoint += '';
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        req.setEndpoint(endpoint);
        req.setMethod(method);
        return req;
    }
    
    // used receive response by sending a http request
    global String getResponse(HttpRequest req)
    {
        try
        {
            Http httpreq = new Http();
            HttpResponse res = httpreq.send(req);
            String reqresponse = res.getBody();
            return reqresponse;
        }
        catch (Exception e)
        {
            return 'Error:' +e.getMessage();
        }
    }
    
    global void deleteApexClass(String oid)
    {
        HttpRequest req = createHttpRequest(endpoint+'/ApexTrigger/'+oid,'DELETE');
        String responseJson = getResponse(req); // Store the result to do something
        system.debug('responseJson ' + responseJson);
    }
    
    @RemoteAction //It is used to delete custom setting records 
    global static boolean fnDelete(rbin__RecycleSearchObjects__c obj) {   
        delete obj;
        return true;
    }
    
    @RemoteAction //It is used to delete custom setting records 
    global static boolean fnDeleteTrackingObject(rbin__Recycle_Bin_Tracking_Objects__c obj) {   
        string triggername = 'rbin'+(obj.Name.contains('__c') ? obj.Name.removeEnd('__c').remove('_') + 'Trigger' : obj.Name+'Trigger' );
        List<ApexTrigger> chktrigger = [SELECT Id, Name, TableEnumOrId, NamespacePrefix, ApiVersion, Status, IsValid FROM ApexTrigger WHERE Name = :triggername];
        if(chktrigger.size() > 0){
            /*SearchObjectSetting setting = new SearchObjectSetting();
            setting.deleteApexClass(chktrigger[0].id);*/
           deleteTrackobjrecord(chktrigger[0].id);
        }
        delete obj;
        return true;
    }
    
    @future(callout = true)
    global static void deleteTrackobjrecord(Id recId){
        SearchObjectSetting setting = new SearchObjectSetting();
        setting.deleteApexClass(recId);
    }
    
    @RemoteAction //It is used to delete custom setting records 
    global static rbin__Recycle_Bin_Setting__c fnGeneral() {  
        return rbin__Recycle_Bin_Setting__c.getOrgDefaults();
    }
    
    @RemoteAction
    global static boolean fnSaveGeneral(rbin__Recycle_Bin_Setting__c obj) { 
        
        List<rbin__Recycle_Bin_Setting__c> rbinsett = [Select rbin__Last_batch_run__c From rbin__Recycle_Bin_Setting__c];
        
        /*if(rbinsett[0].rbin__Last_batch_run__c != null){
            update obj;
        } else {
            obj.rbin__Last_batch_run__c = date.today() - 1;
            update obj;
        }*/
        
        /*if(obj.rbin__Schedule_object_tracking__c){
            createbatchscheduleclass();
            deletetrackedobjtrigger();
        }*/
        if(obj.rbin__Real_time_object_tracking__c){
            //deletescheduledjob();
            createtriggerfortrackedobject();
        } else {
            deletetrackedobjtrigger();
        }
        update obj;
        return true;
    }
    
    @future(callout=true)
    global static void createtriggerfortrackedobject() {
        List<String> trackstring = new List<String>();
        List<rbin__Recycle_Bin_Tracking_Objects__c> obj = [Select Id,Name From rbin__Recycle_Bin_Tracking_Objects__c];
        if(obj.size() > 0) {
            for(rbin__Recycle_Bin_Tracking_Objects__c track : obj){
                string triggername = 'rbin'+(track.Name.contains('__c') ? track.Name.removeEnd('__c').remove('_') + 'Trigger' : track.Name+'Trigger' );
                List<ApexTrigger> chktrigger = [SELECT Id, Name FROM ApexTrigger WHERE Name = :triggername];
                if(chktrigger.size() == 0){
                    SearchObjectSetting setting = new SearchObjectSetting();
                    setting.createApexClass(track.Name);
                }
            }
            
        }
    }
    
    @future(callout=true)
    global static void deletetrackedobjtrigger() {
        List<rbin__Recycle_Bin_Tracking_Objects__c> obj = [Select Id,Name From rbin__Recycle_Bin_Tracking_Objects__c];
        if(obj.size() > 0) {
            for(rbin__Recycle_Bin_Tracking_Objects__c trackedobj : obj){
                string triggername = 'rbin'+(trackedobj.Name.contains('__c') ? trackedobj.Name.removeEnd('__c').remove('_') + 'Trigger' : trackedobj.Name+'Trigger' );
                List<ApexTrigger> chktrigger = [SELECT Id, Name FROM ApexTrigger WHERE Name = :triggername];
                if(chktrigger.size() > 0){
                    SearchObjectSetting setting = new SearchObjectSetting();
                    setting.deleteApexClass(chktrigger[0].id);
                }
            }
        }
    }
    
    global static void deletescheduledjob(){
        List<CronJobDetail> crondetail = [Select Id, Name From CronJobDetail where Name = 'schedule bacth apex'];
        if(crondetail.size() > 0) {
            List<CronTrigger> crontri = [Select Id,CronJobDetailId from CronTrigger where CronJobDetailId = :crondetail[0].Id];
            if(crontri.size() > 0) {
                System.abortJob(crontri[0].Id);   
            }
        }
    }
    
    global class wrapperforweek{
        global String label {get;set;}
        global Integer value {get;set;}
        global boolean isSelected {get;set;}
        
        global wrapperforweek(Integer value,String label){
            this.label = label;
            this.value = value;
            this.isSelected = false;
        }
    }
    
    global class trackingobject {
        global String name {get;set;}
        global String value {get;set;}
    }
}