trigger rbinCommSubscriptionChannelTypeTrigger on CommSubscriptionChannelType (after delete) { 
 if (Trigger.isDelete && Trigger.isAfter) {
 rbin.SendMailForTrackingObject.sendmailwhenrecdelete(Trigger.old);  
} 
}