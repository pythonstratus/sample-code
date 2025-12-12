## Summary: How Sam Discovered the DIAL Data Integrity Issues

Based on the transcript, here's how Samuel approached his testing and discovered the findings:

### The Discovery Process

**1. Started with a Known Problem (TDI Count Issue)**
Sam began by investigating the TDI count discrepancy that had already been identified. While trying to debug this, he stumbled onto the larger referential integrity problems.

**2. Traced Data Relationships Manually**
His methodology was straightforward join-based validation:
- Picked a TIN from `core_dial` to get its `core_sid`
- Joined `core_sid` to `dial_mod` to retrieve related modules
- Compared the result count against the same operation on the legacy replica

**Key finding:** The modernized system returned **1 module** where legacy returned **3 modules** for the same `core_sid`.

**3. Distinct Count Comparisons**
Sam ran distinct counts on key identifier columns across tables:

| Table | Column | Modernized (dial_dev) | Legacy Replica |
|-------|--------|----------------------|----------------|
| `dial_mod` | `mod_sid` | 16 million | 7 million |
| `tin_summary` | `tin_sid` | 1.5 million | 7 million |

**4. Constraint Inspection**
He examined the actual database constraints:
- **dial_dev.dial_mod**: No constraints present
- **Legacy replica**: Has `mod_sid` constraint (FK) referencing `nsid` in `dial_int`

### Root Cause Identified

The `nsid` (sequence ID at column position ~120 in the data) is being **generated in Java** rather than preserving the legacy relationships. While generating sequence IDs seemed logical for handling 16 million modules, it broke the parent-child relationship because:

- Legacy: Multiple modules share the same `mod_sid` (e.g., 3-5 modules per parent)
- Modernized: Each module gets a unique generated ID, destroying the grouping

### Sam's Visual Representation
He created a diagram showing:
- **Modernized**: Arrows from child records pointing to *different* parent records (incorrect)
- **Legacy**: Arrows from child records all pointing to the *same* parent record (correct 1:N relationship)

### Documentation
Sam created **3 JIRA tickets** with:
- PNG screenshots of his comparison queries
- The distinct count evidence
- Constraint analysis

### His Planned Approach Going Forward
1. Comb through the Spring Batch code and stored procedures
2. Do 1:1 comparison with legacy execution flow
3. Examine `calc_sid` procedure in `dial_9_complete` (which updates `tin_sid` in `tin_summary` via bulk collect from `core_dial`)
4. Focus on understanding the sequence ID generation logic in the C/Java `load_dial` component

The key insight: **record counts matched, but relationships didn't**—which is why your team's count-based validation passed but the data was still fundamentally broken.
