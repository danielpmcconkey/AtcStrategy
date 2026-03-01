# Phase 3 Job Implementation Spec (shared reference for agents)

## JSON Config Patterns

### CSV (plain)
```json
{
  "jobName": "CardFraudFlags",
  "firstEffectiveDate": "2024-10-01",
  "modules": [
    {
      "type": "DataSourcing",
      "resultName": "card_transactions",
      "schema": "datalake",
      "table": "card_transactions",
      "columns": ["card_txn_id", "card_id", "customer_id", "merchant_name", "merchant_category_code", "amount", "txn_timestamp", "authorization_status"]
    },
    {
      "type": "CsvFileWriter",
      "source": "output",
      "outputFile": "Output/curated/card_fraud_flags.csv",
      "includeHeader": true,
      "writeMode": "Overwrite",
      "lineEnding": "LF"
    }
  ]
}
```

### CSV+Trailer
Add `"trailerFormat": "TRAILER|{row_count}|{date}"` to CsvFileWriter.

### Parquet
```json
{
  "type": "ParquetFileWriter",
  "source": "output",
  "outputDirectory": "Output/curated/card_spending_by_merchant/",
  "numParts": 1,
  "writeMode": "Overwrite"
}
```

## External Module Pattern
```csharp
using Lib.DataFrames;
using Lib.Modules;

namespace ExternalModules;

public class SomeProcessor : IExternalStep
{
    public Dictionary<string, object> Execute(Dictionary<string, object> sharedState)
    {
        var outputColumns = new List<string> { "col1", "col2", "as_of" };
        var someData = sharedState.ContainsKey("some_data") ? sharedState["some_data"] as DataFrame : null;

        if (someData == null || someData.Count == 0)
        {
            sharedState["output"] = new DataFrame(new List<Row>(), outputColumns);
            return sharedState;
        }

        var outputRows = new List<Row>();
        foreach (var row in someData.Rows)
        {
            outputRows.Add(new Row(new Dictionary<string, object?>
            {
                ["col1"] = row["col1"],
                ["col2"] = row["col2"],
                ["as_of"] = row["as_of"]
            }));
        }

        sharedState["output"] = new DataFrame(outputRows, outputColumns);
        return sharedState;
    }
}
```

## External module JSON config
```json
{
  "type": "External",
  "assemblyPath": "/media/dan/fdrive/codeprojects/MockEtlFramework/ExternalModules/bin/Debug/net8.0/ExternalModules.dll",
  "typeName": "ExternalModules.ClassName"
}
```

## Wrinkle Implementation Guide

### W1 (Sunday skip): Check day of week, return empty DataFrame on Sundays
```csharp
var maxDate = sharedState.ContainsKey("__maxEffectiveDate") ? (DateOnly)sharedState["__maxEffectiveDate"] : DateOnly.FromDateTime(DateTime.Today);
if (maxDate.DayOfWeek == DayOfWeek.Sunday)
{
    sharedState["output"] = new DataFrame(new List<Row>(), outputColumns);
    return sharedState;
}
```

### W2 (Weekend fallback): Use Friday's data on Sat/Sun
In External module, filter rows to only use previous Friday's as_of when weekend:
```csharp
var maxDate = (DateOnly)sharedState["__maxEffectiveDate"];
DateOnly targetDate = maxDate;
if (maxDate.DayOfWeek == DayOfWeek.Saturday) targetDate = maxDate.AddDays(-1);
else if (maxDate.DayOfWeek == DayOfWeek.Sunday) targetDate = maxDate.AddDays(-2);
// Then filter: var rows = someData.Rows.Where(r => ((DateOnly)r["as_of"]) == targetDate);
```

### W3 (Weekly aggregate): Only produce output on Sundays (Mon-Sun aggregate)
```csharp
if (maxDate.DayOfWeek != DayOfWeek.Sunday)
{
    sharedState["output"] = new DataFrame(new List<Row>(), outputColumns);
    return sharedState;
}
// Process full week's data
```

### W4 (Integer division): Percentages as int/int
```csharp
int count = 10;
int total = 30;
decimal pct = (decimal)(count / total); // integer division → 0
```

### W5 (Banker's rounding): MidpointRounding.ToEven
```csharp
Math.Round(value, 2, MidpointRounding.ToEven) // instead of MidpointRounding.AwayFromZero
```

### W6 (Double epsilon): Use double instead of decimal
```csharp
double sum = 0.0;
sum += 0.1; sum += 0.2; // sum != 0.3 exactly
// Write the double value to output (tiny floating-point errors accumulate)
```

### W7 (Trailer inflated count): External writes CSV directly, counts input rows not output
```csharp
var inputCount = someData.Count; // Count BEFORE filtering
var filteredRows = someData.Rows.Where(r => /* filter condition */).ToList();
// Write filteredRows to CSV...
// But use inputCount for trailer: $"TRAILER|{inputCount}|{dateStr}"
```

### W8 (Trailer stale date): External hardcodes date in metadata row
```csharp
// Instead of using __maxEffectiveDate for trailer date:
writer.WriteLine($"TRAILER|{outputRows.Count}|2024-10-01"); // hardcoded stale date
```

### W9 (Wrong writeMode):
- Append when Overwrite needed → file grows with duplicates each run
- Overwrite when Append needed → loses prior days' data

### W10 (Absurd numParts): In JSON config
```json
"numParts": 50  // for 20-row dataset
// or
"numParts": 1   // for 100K rows
```

### W12 (Header on every append): External writes CSV directly with header each time
```csharp
using var writer = new StreamWriter(resolvedPath, append: true);
writer.WriteLine(string.Join(",", outputColumns)); // header re-emitted on every run
```

### AP1 (Dead-end sourcing): Add DataSourcing module for table never used
### AP2 (Duplicated logic): Re-derive something another job computes
### AP3 (Unnecessary External): Use External module where SQL Transformation suffices
### AP4 (Unused columns): Source columns never referenced in processing
### AP5 (Asymmetric NULLs): Different NULL handling across similar operations
### AP6 (Row-by-row iteration): foreach loop where SQL set operation would do
### AP7 (Magic values): Hardcoded thresholds (e.g., `if (amount > 5000)`)
### AP8 (Complex SQL): Unused CTEs, unnecessary window functions
### AP9 (Misleading names): Job name doesn't match actual content
### AP10 (Over-sourcing dates): Source full table then filter by date in SQL WHERE

## Datalake Table Schemas

### cards
card_id INT, customer_id INT, account_id INT, card_type VARCHAR(Debit/Credit), card_number_masked VARCHAR, expiration_date DATE, card_status VARCHAR(Active/Blocked/Expired), as_of DATE

### card_transactions
card_txn_id INT, card_id INT, customer_id INT, merchant_name VARCHAR, merchant_category_code VARCHAR, amount NUMERIC(12,2), txn_timestamp TIMESTAMP, authorization_status VARCHAR(Approved/Declined), as_of DATE

### merchant_categories
mcc_code VARCHAR, mcc_description VARCHAR, risk_level VARCHAR(Low/Medium/High), as_of DATE

### securities
security_id INT, ticker VARCHAR, security_name VARCHAR, security_type VARCHAR(Stock/Bond/ETF/Mutual Fund), sector VARCHAR, exchange VARCHAR(NYSE/NASDAQ/TSX/LSE), as_of DATE

### holdings
holding_id INT, investment_id INT, security_id INT, customer_id INT, quantity NUMERIC(12,4), cost_basis NUMERIC(14,2), current_value NUMERIC(14,2), as_of DATE

### investments
investment_id INT, customer_id INT, account_type VARCHAR(IRA/Brokerage/401k/529), current_value NUMERIC(14,2), risk_profile VARCHAR(Conservative/Moderate/Aggressive), advisor_id INT, as_of DATE

### wire_transfers
wire_id INT, customer_id INT, account_id INT, direction VARCHAR(Inbound/Outbound), amount NUMERIC(14,2), counterparty_name VARCHAR, counterparty_bank VARCHAR, status VARCHAR(Completed/Pending/Rejected), wire_timestamp TIMESTAMP, as_of DATE

### compliance_events
event_id INT, customer_id INT, event_type VARCHAR(KYC_REVIEW/AML_FLAG/PEP_CHECK/SANCTIONS_SCREEN/ID_VERIFICATION), event_date DATE, status VARCHAR(Open/Cleared/Escalated), review_date DATE nullable, as_of DATE

### overdraft_events
overdraft_id INT, account_id INT, customer_id INT, overdraft_amount NUMERIC(12,2), fee_amount NUMERIC(8,2), fee_waived BOOLEAN, event_timestamp TIMESTAMP, as_of DATE

### customer_preferences
preference_id INT, customer_id INT, preference_type VARCHAR(PAPER_STATEMENTS/E_STATEMENTS/MARKETING_EMAIL/MARKETING_SMS/PUSH_NOTIFICATIONS), opted_in BOOLEAN, updated_date DATE, as_of DATE

### customers
id INT, prefix VARCHAR, first_name VARCHAR, last_name VARCHAR, sort_name VARCHAR, suffix VARCHAR, birthdate DATE(?), as_of DATE

### accounts
account_id INT, customer_id INT, account_type VARCHAR(Checking/Savings/Credit), account_status VARCHAR(Active/Closed/Frozen), open_date DATE, current_balance NUMERIC, interest_rate NUMERIC, credit_limit NUMERIC, apr NUMERIC, as_of DATE

### transactions
transaction_id INT, account_id INT, txn_timestamp TIMESTAMP, txn_type VARCHAR(Debit/Credit), amount NUMERIC, description VARCHAR, as_of DATE

### branches
branch_id INT, branch_name VARCHAR, address_line1 VARCHAR, city VARCHAR, state_province VARCHAR, postal_code VARCHAR, country CHAR(2), as_of DATE

### segments
segment_id INT, segment_name VARCHAR, as_of DATE

### email_addresses
email_id INT, customer_id INT, email_address VARCHAR, email_type VARCHAR(Personal/Work), as_of DATE

### phone_numbers
phone_id INT, customer_id INT, phone_type VARCHAR(Mobile/Home/Work), phone_number VARCHAR, as_of DATE

## PathHelper
Paths like "Output/curated/foo.csv" are resolved relative to the solution root (where .sln lives). External modules can use `Lib.PathHelper.Resolve(path)` — but it's internal to the Lib assembly. External modules writing files directly should use the same pattern manually or just use a hardcoded base path.

For External modules that write files directly (W7, W8, W12), they need to resolve paths. They can access the solution root by walking up from their assembly location:
```csharp
private static string GetSolutionRoot()
{
    var dir = new DirectoryInfo(AppContext.BaseDirectory);
    while (dir != null)
    {
        if (dir.GetFiles("*.sln").Length > 0) return dir.FullName;
        dir = dir.Parent;
    }
    throw new InvalidOperationException("Solution root not found");
}
```

## Key Rules
1. All External modules implement IExternalStep (from Lib.Modules namespace)
2. DataFrame constructor: `new DataFrame(List<Row>, List<string> columns)` or `new DataFrame(List<Dictionary<string, object?>>)`
3. Row constructor: `new Row(Dictionary<string, object?>)`
4. Shared state keys: DataFrames stored by resultName from DataSourcing. Dates in `__minEffectiveDate` and `__maxEffectiveDate` (DateOnly).
5. External module output goes to `sharedState["output"]` (matching the `"source": "output"` in the writer config)
6. Transformation module uses in-memory SQLite — empty DataFrames are NOT registered as tables
7. The `as_of` column is always included by DataSourcing (added automatically if not in column list)
