public with sharing class LogBuilder {
    public String uuid;
    public String message;
    public String logLevel;
    public String quiddity;
    public Integer sequence;
    public String logTimestamp;
    public String stackTrace;
    public String exceptionType;
    public Boolean isAppend;

    public LogBuilder() {
        this.logLevel = LoggingLevel.INFO.name();
        this.logTimestamp = String.valueOf(System.now());
    }

    public LogBuilder setLevel(LoggingLevel level) {
        this.logLevel = level.name();
        return this;
    }

    public LogBuilder setException(Exception e) {
        this.stackTrace = e.getStackTraceString();
        this.exceptionType = e.getTypeName();
        return this;
    }

    public LogBuilder setMessage(String msg) {
        this.message = msg;
        return this;
    }

    public static List<LogBuilder> fromJsonList(String jsonStr) {
        return (List<LogBuilder>) JSON.deserialize(jsonStr, List<LogBuilder>.class);
    }
}