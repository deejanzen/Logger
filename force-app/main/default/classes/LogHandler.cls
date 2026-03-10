public with sharing class LogHandler {
    public static void handle(List<LogEvent__e> events) {
        Set<String> seenUUIDs = new Set<String>();
        List<Log__c> newParents = new List<Log__c>();
        List<Log_Entry__c> entries = new List<Log_Entry__c>();

        for (LogEvent__e evt : events) {
            for (LogBuilder entry : LogBuilder.fromJsonList(evt.Payload__c)) {
                if (!seenUUIDs.contains(entry.uuid)) {
                    seenUUIDs.add(entry.uuid);
                    if (entry.isAppend != true) {
                        newParents.add(new Log__c(
                            Name              = entry.quiddity,
                            UUID__c           = entry.uuid,
                            Running_User__c   = UserInfo.getUserId(),
                            Transaction_Id__c = Request.getCurrent().getRequestId()
                        ));
                    }
                }
                Log_Entry__c e = new Log_Entry__c();
                e.Log__r = new Log__c(UUID__c = entry.uuid);
                e.Message__c = entry.message;
                e.Log_Level__c = entry.logLevel;
                e.Sequence__c = entry.sequence;
                e.Stack_Trace__c = entry.stackTrace;
                e.Exception_Type__c = entry.exceptionType;
                try {
                    e.Log_Timestamp__c = DateTime.valueOf(entry.logTimestamp);
                } catch (Exception parseEx) {
                    e.Log_Timestamp__c = System.now();
                }
                entries.add(e);
            }
        }

        List<SObject> allRecords = new List<SObject>();
        allRecords.addAll(newParents);
        allRecords.addAll(entries);
        if (!allRecords.isEmpty()) {
            insert allRecords;
        }
    }
}