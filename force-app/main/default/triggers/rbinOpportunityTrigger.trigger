trigger rbinOpportunityTrigger on Opportunity (after delete) { 
 if (Trigger.isDelete && Trigger.isAfter) {
 rbin.SendMailForTrackingObject.sendmailwhenrecdelete(Trigger.old);  
} 
}