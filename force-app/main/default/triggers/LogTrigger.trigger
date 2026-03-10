trigger LogTrigger on LogEvent__e (after insert) {
    LogHandler.handle(Trigger.new);
}