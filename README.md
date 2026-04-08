# sf-nebula-dml-ops

* Light DML wrapper that logs to Nebula.
* Requires [Nebula Logger](https://github.com/jongpie/NebulaLogger).


## Usage

### Methods

| DML Operation | DmlOps Method           |
| ------------- | ----------------------- |
| Insert        | DmlOps.create()         |
| Update        | DmlOps.modify()         |
| Upsert        | DmlOps.upsrt() // TODO  |
| Delete        | DmlOps.remove() // TODO |


### Parameters
All methods accept the below parameters

| Parameter | Type           | Required |
| --------- | -------------- | -------- |
| records   | List<SObject>  | Yes      |
| options   | DmlOps.Options | No       |


### DmlOps.Options

| Property          | Type      | Description                                                                                                                                       |
| ----------------- | --------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| `allOrNone`       | `Boolean` | Same as the standard Salesforce Database class `allOrNone` parameter. Defaults to `false` (Note: that is the opposite of the standard behaviour) |
| `logSuccess`      | `Boolean` | Whether to log successes or not. Defaults to `false`                                                                                              |
| `loggingScenario` | `String`  | Sets the Nebula Logging Scenario. Defaults to `DML: {Object}`            

<br>

## Examples


### Insert Records
```
List<Account> accounts = new List<Account>{new Account()};
DmlOps.create(accounts);
```

### Update Records
```
List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
accounts[0].Name = null;
DmlOps.modify(accounts);
```

### Insert Records - with results
Results are always available to the caller, for further handling e.g.
```
List<Account> accounts = new List<Account>{new Account()};
List<Database.SaveResults> results = DmlOps.create(accounts);
```


### Insert Records with Options
```
List<Account> accounts = new List<Account>{new Account()};
DmlOps.Options options = new DmlOps.Options();
options.loggingScenario = 'Test Scenario';
DmlOps.create(accounts);
```

#### Options can also be passed as a Map
```
List<Account> accounts = new List<Account>{new Account()};
DmlOps.create(accounts, new DmlOps.Options(new Map<String, Object>{'loggerScenario' => 'Test Scenario'}));
```

#### Or as a JSON object
```
List<Account> accounts = new List<Account>{new Account()};
DmlOps.create(accounts, new DmlOps.Options('{"loggingScenario": "Test Scenario1"}'));
```


### Insert with allOrNone = True

Exceptions will be logged, and then thrown back to the caller.

```
List<Account> accounts = new List<Account>{new Account()};

try {
    DmlOps.create(accounts, new DmlOps.Options('{"allOrNone": true}'));
} catch (DmlException e) {
    // Handle as needed
}
```

## Example Logs

### Log
<img width="2305" height="559" alt="Image" src="https://github.com/user-attachments/assets/0a4b293b-cb37-4ae6-a86f-1b7d15119fc3" />

### Log Entry
<img width="1782" height="742" alt="Image" src="https://github.com/user-attachments/assets/2f015653-fb4a-4eab-883a-f9b4c46b77f2" />

### Log Entry Details
<img width="1800" height="749" alt="Image" src="https://github.com/user-attachments/assets/efbc713e-d682-4bc0-a91f-f3bd19739e26" />

