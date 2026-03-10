public with sharing class Logger {
    @TestVisible private static List<LogBuilder> logQueue = new List<LogBuilder>();
    @TestVisible private static Integer sequence = 0;
    private static String currentUUID;
    @TestVisible private static Boolean hasExplicitUUID = false;
    @TestVisible private static Integer platformEventsFired = 0;
    public static final Integer PE_LIMIT = 150;

    public static void setUUID(String uuid) {
        currentUUID = uuid;
        hasExplicitUUID = true;
    }

    public static String getUUID() {
        return currentUUID;
    }

    public static LogBuilder log(String message) {
        return log(LoggingLevel.INFO, message);
    }

    public static LogBuilder log(LoggingLevel level, String message) {
        LogBuilder entry = new LogBuilder()
            .setLevel(level)
            .setMessage(message);
        entry.uuid = getCurrentUUID();
        entry.sequence = sequence++;
        entry.quiddity = autoDetectQuiddity();
        entry.isAppend = hasExplicitUUID;
        logQueue.add(entry);
        return entry;
    }

    public static LogBuilder log(Exception e) {
        LogBuilder entry = new LogBuilder()
            .setLevel(LoggingLevel.ERROR)
            .setMessage(e.getMessage())
            .setException(e);
        entry.uuid = getCurrentUUID();
        entry.sequence = sequence++;
        entry.quiddity = autoDetectQuiddity();
        entry.isAppend = hasExplicitUUID;
        logQueue.add(entry);
        return entry;
    }

    public static void saveLogs() {
        try {
            if (logQueue.isEmpty()) {
                return;
            }
            if (platformEventsFired >= PE_LIMIT) {
                System.debug(LoggingLevel.WARN, 'Logger: platform event limit reached (' + PE_LIMIT + '), logs dropped.');
                return;
            }
            List<LogBuilder> filtered = new List<LogBuilder>();
            for (LogBuilder entry : logQueue) {
                LoggingLevel lvl = LoggingLevel.valueOf(entry.logLevel);
                if (LoggerSettings.isLevelEnabled(lvl)) {
                    filtered.add(entry);
                }
            }
            logQueue.clear();
            sequence = 0;
            if (filtered.isEmpty()) {
                return;
            }
            Database.SaveResult result = EventBus.publish(
                new LogEvent__e(Payload__c = JSON.serialize(filtered))
            );
            if (result.isSuccess()) {
                platformEventsFired++;
            } else {
                System.debug(LoggingLevel.ERROR, 'Logger: failed to publish LogEvent__e — ' + result.getErrors());
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Logger.saveLogs() failed silently: ' + e.getMessage() + ' — ' + e.getStackTraceString());
        }
    }

    public static String generateUUID() {
        return System.UUID.randomUUID().toString();
    }

    private static String getCurrentUUID() {
        if (currentUUID == null) {
            currentUUID = generateUUID();
            hasExplicitUUID = false;
        }
        return currentUUID;
    }

    private static String autoDetectQuiddity() {
        try {
            return Request.getCurrent().getQuiddity().name();
        } catch (Exception e) {
            return null;
        }
    }
}