@isTest
public with sharing class LoggerTest {

    @isTest
    static void testLogBuildsCorrectFields() {
        LoggerSettings.cachedEnabled = true;
        LoggerSettings.cachedMask = 254L;

        LogBuilder entry = Logger.log(LoggingLevel.INFO, 'Test message');

        System.assertEquals('INFO', entry.logLevel);
        System.assertEquals('Test message', entry.message);
        System.assertEquals(0, entry.sequence);
        System.assertNotEquals(null, entry.uuid);
        System.assertNotEquals(null, entry.logTimestamp);
    }

    @isTest
    static void testLogExceptionBuildsCorrectFields() {
        LoggerSettings.cachedEnabled = true;
        LoggerSettings.cachedMask = 254L;

        Exception ex;
        try {
            Integer i = Integer.valueOf('not-a-number');
        } catch (Exception e) {
            ex = e;
        }

        LogBuilder entry = Logger.log(ex);

        System.assertEquals('ERROR', entry.logLevel);
        System.assertNotEquals(null, entry.stackTrace);
        System.assertNotEquals(null, entry.exceptionType);
    }

    @isTest
    static void testSaveLogsEmptyQueueDoesNotPublish() {
        Logger.logQueue.clear();
        Logger.platformEventsFired = 0;

        Logger.saveLogs();

        System.assertEquals(0, Logger.platformEventsFired);
    }

    @isTest
    static void testSaveLogsAtPELimitDropsLogs() {
        LoggerSettings.cachedEnabled = true;
        LoggerSettings.cachedMask = 254L;
        Logger.platformEventsFired = Logger.PE_LIMIT;

        Logger.log('Will be dropped');
        Logger.saveLogs();

        System.assertEquals(Logger.PE_LIMIT, Logger.platformEventsFired);
    }

    @isTest
    static void testSaveLogsFiltersDisabledLevels() {
        // Only DEBUG enabled (bit 4 = 16)
        LoggerSettings.cachedEnabled = true;
        LoggerSettings.cachedMask = 16L;
        Logger.logQueue.clear();
        Logger.platformEventsFired = 0;

        Logger.log(LoggingLevel.INFO, 'Should be filtered out');
        Logger.saveLogs();

        // Queue cleared but no PE fired because filtered list was empty
        System.assertEquals(0, Logger.platformEventsFired);
        System.assertEquals(0, Logger.logQueue.size());
    }

    @isTest
    static void testIsLevelEnabled() {
        LoggerSettings.cachedEnabled = true;
        // INFO ordinal = 3, bit = 1<<3 = 8
        LoggerSettings.cachedMask = 8L;

        System.assertEquals(true, LoggerSettings.isLevelEnabled(LoggingLevel.INFO));
        System.assertEquals(false, LoggerSettings.isLevelEnabled(LoggingLevel.DEBUG));
        System.assertEquals(false, LoggerSettings.isLevelEnabled(LoggingLevel.ERROR));
    }

    @isTest
    static void testIsLevelEnabledWhenDisabled() {
        LoggerSettings.cachedEnabled = false;
        LoggerSettings.cachedMask = 254L;

        System.assertEquals(false, LoggerSettings.isLevelEnabled(LoggingLevel.INFO));
        System.assertEquals(false, LoggerSettings.isLevelEnabled(LoggingLevel.ERROR));
    }

    @isTest
    static void testLogHandlerUpsertsLogAndInsertEntries() {
        LogBuilder entry = new LogBuilder();
        entry.uuid = 'test-uuid-abcd-1234-efgh';
        entry.message = 'Handler test message';
        entry.logLevel = 'INFO';
        entry.quiddity = 'SYNCHRONOUS';
        entry.sequence = 0;
        entry.logTimestamp = String.valueOf(System.now());
        entry.isAppend = false;

        LogEvent__e evt = new LogEvent__e(Payload__c = JSON.serialize(new List<LogBuilder>{ entry }));

        Test.startTest();
        LogHandler.handle(new List<LogEvent__e>{ evt });
        Test.stopTest();

        List<Log__c> logs = [SELECT UUID__c, Name FROM Log__c WHERE UUID__c = 'test-uuid-abcd-1234-efgh'];
        System.assertEquals(1, logs.size());
        System.assertEquals('SYNCHRONOUS', logs[0].Name);

        List<Log_Entry__c> entries = [
            SELECT Message__c, Log_Level__c, Sequence__c
            FROM Log_Entry__c
            WHERE Log__r.UUID__c = 'test-uuid-abcd-1234-efgh'
        ];
        System.assertEquals(1, entries.size());
        System.assertEquals('Handler test message', entries[0].Message__c);
        System.assertEquals('INFO', entries[0].Log_Level__c);
        System.assertEquals(0, entries[0].Sequence__c);
    }

    @isTest
    static void testBatchUUIDSharesOneParentLog() {
        String sharedUUID = 'batch-uuid-abcd-1234-efgh';
        insert new Log__c(Name = 'BATCH_APEX', UUID__c = sharedUUID,
                          Running_User__c = UserInfo.getUserId());

        LogBuilder e1 = new LogBuilder();
        e1.uuid = sharedUUID;
        e1.message = 'Batch execute 1';
        e1.logLevel = 'INFO';
        e1.quiddity = 'BATCH_APEX';
        e1.sequence = 0;
        e1.logTimestamp = String.valueOf(System.now());
        e1.isAppend = true;

        LogBuilder e2 = new LogBuilder();
        e2.uuid = sharedUUID;
        e2.message = 'Batch execute 2';
        e2.logLevel = 'INFO';
        e2.quiddity = 'BATCH_APEX';
        e2.sequence = 1;
        e2.logTimestamp = String.valueOf(System.now());
        e2.isAppend = true;

        LogEvent__e evt1 = new LogEvent__e(Payload__c = JSON.serialize(new List<LogBuilder>{ e1 }));
        LogEvent__e evt2 = new LogEvent__e(Payload__c = JSON.serialize(new List<LogBuilder>{ e2 }));

        Test.startTest();
        LogHandler.handle(new List<LogEvent__e>{ evt1, evt2 });
        Test.stopTest();

        List<Log__c> logs = [SELECT UUID__c FROM Log__c WHERE UUID__c = :sharedUUID];
        System.assertEquals(1, logs.size(), 'Both execute() calls should share one Log__c parent');

        List<Log_Entry__c> entries = [
            SELECT Message__c
            FROM Log_Entry__c
            WHERE Log__r.UUID__c = :sharedUUID
            ORDER BY Sequence__c
        ];
        System.assertEquals(2, entries.size());
        System.assertEquals('Batch execute 1', entries[0].Message__c);
        System.assertEquals('Batch execute 2', entries[1].Message__c);
    }

    @isTest
    static void testAppendSkipsParentDML() {
        String uuid = 'append-uuid-abcd-1234-efgh';
        insert new Log__c(Name = 'SYNCHRONOUS', UUID__c = uuid,
                          Running_User__c = UserInfo.getUserId());

        LogBuilder entry = new LogBuilder();
        entry.uuid = uuid;
        entry.message = 'Appended entry';
        entry.logLevel = 'INFO';
        entry.quiddity = 'SYNCHRONOUS';
        entry.sequence = 0;
        entry.logTimestamp = String.valueOf(System.now());
        entry.isAppend = true;

        LogEvent__e evt = new LogEvent__e(Payload__c = JSON.serialize(new List<LogBuilder>{ entry }));

        Test.startTest();
        LogHandler.handle(new List<LogEvent__e>{ evt });
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM Log__c WHERE UUID__c = :uuid],
            'No duplicate Log__c should be created when isAppend = true');

        List<Log_Entry__c> entries = [
            SELECT Message__c FROM Log_Entry__c WHERE Log__r.UUID__c = :uuid
        ];
        System.assertEquals(1, entries.size());
        System.assertEquals('Appended entry', entries[0].Message__c);
    }

    @isTest
    static void testGenerateUUID() {
        String uuid1 = Logger.generateUUID();
        String uuid2 = Logger.generateUUID();
        System.assertNotEquals(null, uuid1);
        System.assertEquals(36, uuid1.length());
        System.assertNotEquals(uuid1, uuid2);
    }
}