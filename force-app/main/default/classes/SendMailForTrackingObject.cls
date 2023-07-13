global with sharing class SendMailForTrackingObject {
    
    global static void sendmailwhenrecdelete(List<sObject> sobjLst){
        Set<Id> recordIds = new Set<Id>();
        String deletedobjectname = '';
        String deletedobjectapi = '';
        for(sObject sobj : sobjLst) {
            recordIds.add((Id)sobj.get('Id'));
            if(String.isBlank(deletedobjectname)){
                Id rid = (Id)sobj.get('Id');
                deletedobjectname = rid.getSObjectType().getDescribe().getLabel();
                deletedobjectapi = rid.getSObjectType().getDescribe().getName();
            }
        }
        List<rbin__Recycle_Bin_Setting__c> rbinsetting = new List<rbin__Recycle_Bin_Setting__c>{rbin__Recycle_Bin_Setting__c.getOrgDefaults()};
            if(rbinsetting.size() > 0 && recordIds.size() > 0){
                sendMail(rbinsetting[0].rbin__Send_record_deletion_email_to__c,recordIds,deletedobjectname,deletedobjectapi);
            }
    }
    
    @future
    global static void sendMail(String toMail, Set<Id> recordIds,String objName,String deletedobjectapi){
        List<String> sendtomails = new List<String>();
        List<rbin__Recycle_Bin_Setting__c> rbinsetting = new List<rbin__Recycle_Bin_Setting__c>{rbin__Recycle_Bin_Setting__c.getOrgDefaults()};
            String sdt = String.valueOf(String.valueOf(rbinsetting[0].rbin__Last_batch_run__c).split('-')[1] + '/' + String.valueOf(rbinsetting[0].rbin__Last_batch_run__c).split('-')[2] + '/' + rbinsetting[0].rbin__Last_batch_run__c).split('-')[0];            
        Date d = date.today();
        String edt = d.month() + '/' + d.day() + '/' + d.year();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if(toMail.contains(',')) {
            sendtomails.addAll(toMail.split(','));
        } else {
            sendtomails.add(toMail);
        }
        email.saveAsActivity = false;
        //email.setTargetObjectId(UserInfo.getUserId());
        email.setToAddresses(sendtomails);
        email.setSubject(objName + ' Deleted record detail.');
        
        String body = 'Hi Admin, <br/><br/>' + UserInfo.getName() + ' has deleted ' + recordIds.size() + ' ' + objName + ' Records. <br/><br/>Below is the list of deleted record ids.<br/><br/><table border="1" style="border-collapse: collapse;"><tr><th>Deleted Record Ids</th><td>&nbsp;&nbsp;';
        
        for(Id rid : recordIds){
            body += rid + ', ';
        }
        body = body.removeEnd(', ');
        body += '</td></tr><tr><th>Total Deleted Records</th><td>&nbsp;&nbsp;' + recordIds.size() + '</td></tr><tr><th>More Details</th><td>Click <a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/rbin__Recycle_Bin_Manager?Object='+deletedobjectapi+'&FromDate='+sdt+'&ToDate='+edt+'">here</a></td></tr></table><br/><br/>Thanks,<br/>Recycle Bin Manager';
        
        email.setHtmlBody(body);
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }catch(exception e){
            System.debug(e.getMessage());
        }
    }
    
    global static void processbatchedrecords(Map<String, Set<Id>> sobjectdeletedrec) {
        String mailBody = '';
        
        List<rbin__Recycle_Bin_Setting__c> rbinsetting = new List<rbin__Recycle_Bin_Setting__c>{rbin__Recycle_Bin_Setting__c.getOrgDefaults()};
            
            String sdt = String.valueOf(String.valueOf(rbinsetting[0].rbin__Last_batch_run__c).split('-')[1] + '/' + String.valueOf(rbinsetting[0].rbin__Last_batch_run__c).split('-')[2] + '/' + rbinsetting[0].rbin__Last_batch_run__c).split('-')[0];            
        Date d = date.today();
        String edt = d.month() + '/' + d.day() + '/' + d.year();
        
        mailBody += 'Hi Admin, <br/><br/>Below is the list of deleted object record id\'s.<br/><br/><table border="1"><tr><th>Object Name</th><th>Deleted Record Id\'s</th><th>Total Deleted Records</th><th>More details</th><tr>';
        
        for(String objname : sobjectdeletedrec.keySet()){
            mailBody += '<tr><th>' + objname + '</th><td>';
            for(Id recid : sobjectdeletedrec.get(objname)){
                mailBody += recid + ', ';
            }
            mailBody = mailBody.removeEnd(', ');
            mailBody += '</td><td align="center">'+sobjectdeletedrec.get(objname).size()+'</td><td>Click <a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/apex/rbin__Recycle_Bin_Manager?Object='+objname+'&FromDate='+sdt+'&ToDate='+edt+'">here</a></td></tr>';
        }
        mailBody += '</table><br/><br/>Thanks,<br/>Recycle Bin Manager';
        sendmailforbatchrecords(rbinsetting[0].rbin__Send_record_deletion_email_to__c, mailBody);
        
    }
    
    global static void sendmailforbatchrecords(String toMail, String body) {
        List<String> sendtomails = new List<String>();
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if(toMail.contains(',')) {
            sendtomails.addAll(toMail.split(','));
        } else {
            sendtomails.add(toMail);
        }
        
        email.setToAddresses(sendtomails);
        
        email.setSubject('Deleted record detail.');
        
        email.setHtmlBody(body);
        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }catch(exception e){
            System.debug(e.getMessage());
        }
    }
    
    global static void updatelastbatchrun() {
        List<rbin__Recycle_Bin_Setting__c> rbinsetting = new List<rbin__Recycle_Bin_Setting__c>{rbin__Recycle_Bin_Setting__c.getOrgDefaults()};
            if(rbinsetting.size() > 0) {
                rbinsetting[0].rbin__Last_batch_run__c = date.today();
                update rbinsetting[0];
            }
    }
}