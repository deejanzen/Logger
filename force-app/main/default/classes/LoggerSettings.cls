public with sharing class LoggerSettings {
    @TestVisible private static Long cachedMask;
    @TestVisible private static Boolean cachedEnabled;

    // Fail open: all levels except NONE (bits 1–7)
    private static final Long DEFAULT_MASK = 254L;

    public static Boolean isEnabled() {
        if (cachedEnabled == null) {
            LoggerSettings__mdt setting = LoggerSettings__mdt.getInstance('Default');
            cachedEnabled = setting != null ? setting.Is_Enabled__c : true;
        }
        return cachedEnabled;
    }

    public static Boolean isLevelEnabled(LoggingLevel level) {
        if (!isEnabled()) {
            return false;
        }
        Long mask = getLevelMask();
        Long bit = 1L << level.ordinal();
        return (mask & bit) != 0;
    }

    public static Long getLevelMask() {
        if (cachedMask == null) {
            LoggerSettings__mdt setting = LoggerSettings__mdt.getInstance('Default');
            cachedMask = setting != null ? (Long) setting.Log_Level_Mask__c : DEFAULT_MASK;
        }
        return cachedMask;
    }

    public static void deployLevelMask(Set<LoggingLevel> levels) {
        Long mask = 0L;
        for (LoggingLevel lvl : levels) {
            mask |= (1L << lvl.ordinal());
        }
        CustomMDTMgr.builder()
            .addMetadata('LoggerSettings.Default', new Map<String, Object>{
                'Log_Level_Mask__c' => mask,
                'Is_Enabled__c' => true
            })
            .build()
            .deploy();
        cachedMask = null;
        cachedEnabled = null;
    }
}