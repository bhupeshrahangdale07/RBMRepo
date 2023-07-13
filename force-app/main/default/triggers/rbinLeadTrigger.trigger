trigger rbinLeadTrigger on Lead (after delete) { 
 if (Trigger.isDelete && Trigger.isAfter) {
 rbin.SendMailForTrackingObject.sendmailwhenrecdelete(Trigger.old);  
} 
}