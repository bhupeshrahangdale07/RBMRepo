trigger rbinDuplicateRecordItemTrigger on DuplicateRecordItem (after delete) { 
 if (Trigger.isDelete && Trigger.isAfter) {
 rbin.SendMailForTrackingObject.sendmailwhenrecdelete(Trigger.old);  
} 
}