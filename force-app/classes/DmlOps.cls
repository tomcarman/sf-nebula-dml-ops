public without sharing class DmlOps {
    private static final String DML_INSERT = 'Insert';
    private static final String DML_UPDATE = 'Update';
    private static final String DML_UPSERT = 'Upsert';

    public class Options {
        public Boolean allOrNone;
        public Boolean logSuccess;
        public String loggingScenario;
        public Schema.SObjectField externalIdField;

        public Options() {
            // Defaults
            this.allOrNone = false;
            this.logSuccess = false;
        }

        // Map constructor
        public Options(Map<String, Object> optionsMap) {
            this();
            this.allOrNone = (Boolean) optionsMap.get('allOrNone') ?? this.allOrNone;
            this.logSuccess = (Boolean) optionsMap.get('logSuccess') ?? this.logSuccess;
            this.loggingScenario = (String) optionsMap.get('loggingScenario') ?? this.loggingScenario;
            this.externalIdField = (Schema.SObjectField) optionsMap.get('externalIdField') ?? null;
        }

        // Json Constructor
        public Options(String jsonString) {
            this((Map<String, Object>) JSON.deserializeUntyped(jsonString));
        }
    }

    public static List<Database.SaveResult> create(List<SObject> records) {
        return create(records, new Options());
    }

    public static List<Database.SaveResult> modify(List<SObject> records) {
        return modify(records, new Options());
    }

    public static List<Database.UpsertResult> upsrt(List<SObject> records) {
        return upsrt(records, new Options());
    }

    /*
    public static List<Database.DeleteResult> remove(List<SObject> records) {
        return remove(records, new Options());
    }*/

    public static List<Database.SaveResult> create(List<SObject> records, Options options) {
        return createOrModify(DML_INSERT, records, options);
    }

    public static List<Database.SaveResult> modify(List<SObject> records, Options options) {
        return createOrModify(DML_UPDATE, records, options);
    }

    public static List<Database.UpsertResult> upsrt(List<SObject> records, Options options) {
        if (records == null || records.isEmpty()) {
            logInvalidRecords('upsrt', records, options);
            return null;
        }

        String objectType = String.valueOf(records[0].getSObjectType());

        setLogScenario(options, 'DML: ' + objectType);

        List<Database.UpsertResult> results;

        try {
            if (options.externalIdField != null) {
                results = Database.upsert(records, options.externalIdField, options.allOrNone);
            } else {
                results = Database.upsert(records, options.allOrNone);
            }
        } catch (System.DmlException e) {
            // Catch Exceptions for allOrNone = true, log and re-throw.
            logException(DML_UPSERT, objectType, e);
            Logger.saveLog();
            throw e;
        }

        for (Database.UpsertResult result : results) {
            if (!result.isSuccess() || options.logSuccess) {
                logResult(DML_UPSERT, objectType, result);
            }
        }

        Logger.saveLog();
        return results;
    }

    /*
    public static List<Database.DeleteResult> remove(List<SObject> records, Options options) {
        // TODO
        return null;
    }*/

    private static List<Database.SaveResult> createOrModify(String dmlType, List<SObject> records, Options options) {
        String method = dmlType == DML_INSERT ? 'create' : 'modify';

        if (records == null || records.isEmpty()) {
            logInvalidRecords(method, records, options);
            return null;
        }

        String objectType = String.valueOf(records[0].getSObjectType());

        setLogScenario(options, 'DML: ' + objectType);

        List<Database.SaveResult> results;

        try {
            if (dmlType == DML_INSERT) {
                results = Database.insert(records, options.allOrNone);
            } else if (dmlType == DML_UPDATE) {
                results = Database.update(records, options.allOrNone);
            }
        } catch (System.DmlException e) {
            // Catch Exceptions for allOrNone = true, log and re-throw.
            logException(dmlType, objectType, e);
            Logger.saveLog();
            throw e;
        }

        for (Database.SaveResult result : results) {
            if (!result.isSuccess() || options.logSuccess) {
                logResult(dmlType, objectType, result);
            }
        }

        Logger.saveLog();
        return results;
    }

    private static void logResult(String dmlType, String objectName, Database.SaveResult result) {
        if (result.isSuccess()) {
            Logger.info('Successfully ' + dmlType + 'd ' + objectName + ' record with Id: ' + result.getId());
        } else {
            Logger.error('Failed to ' + dmlType + ' ' + objectName + ' record.', result);
        }
    }

    private static void logResult(String dmlType, String objectName, Database.UpsertResult result) {
        if (result.isSuccess()) {
            Logger.info('Successfully Upserted ' + objectName + ' record with Id: ' + result.getId());
        } else {
            Logger.error('Failed to ' + dmlType + ' ' + objectName + ' record.', result);
        }
    }

    private static void logException(String dmlType, String objectName, DmlException e) {
        Logger.error('Failed to ' + dmlType + ' ' + objectName + ' record(s).', e);
    }

    private static void logInvalidRecords(String method, List<SObject> records, Options options) {
        setLogScenario(options, 'DML: Unknown');
        String errorType = records == null ? 'null' : 'empty';
        Logger.error('DmlOps.' + method + '() called with ' + errorType + ' list of records');
        Logger.saveLog();
    }

    /* Sets Nebula Log Scenario, using the one supplied in DmlOps.Options, or defaulting to "DML: {ObjectType}"*/
    private static void setLogScenario(Options options, String autogenerated) {
        Logger.setScenario(options.loggingScenario ?? autogenerated);
    }
}