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



## Tone of the Call

The overall tone was **professional, collaborative, and diplomatically direct**. A few notable dynamics:

**Eddie (Speaker B)** - Managed the conversation carefully, balancing several objectives:
- Appreciative but firm about transitioning ownership away from Santosh's team
- Gently redirected Santosh when he started problem-solving ("that wasn't the purpose of the call today")
- Acknowledged the hard work put in while being clear the deliverable wasn't as complete as expected
- Used phrases like "I love that about you" when tempering Santosh's instinct to jump back in

**Sam (Speaker C)** - Technical and measured:
- Presented findings factually without being accusatory
- Repeatedly acknowledged the team's effort ("hours upon hours working on this")
- Focused on problem description rather than blame

**Santosh (Speaker A)** - Receptive and accountable:
- Took the feedback gracefully ("thanks a lot for highlighting this")
- Self-deprecating humor at the end ("dial mod is going to be in our heads for this weekend")
- Instinctively wanted to help fix it, had to be gently steered away

**Corey (Speaker D)** - Process-oriented:
- Focused on sprint planning and resource allocation
- Set boundaries (9 hours for Ganga) while remaining flexible

There was a slight undercurrent of **managing expectations**—Eddie making it clear the work wasn't "code complete as originally thought" and "there's more discrepancies than initially told to us."

---

## Other Issues Eddie Mentioned

Eddie outlined **three main issues** at the start:

| Issue | Description | Scale |
|-------|-------------|-------|
| **1. Constraints/Referential Integrity** | Missing PK-FK constraints on `dial_mod` causing "headless" modules with no correct relationship to `dial_int` | ~8.2 million orphaned rows |
| **2. Mod Score Mismatches** | Count discrepancies between modernized and legacy in model score data | ~9-10 million difference |
| **3. Tin Summary Mismatches** | `tin_sid` relationship issues in `tin_summary` table | Tens to hundreds of thousands |

Eddie also mentioned a **character set mismatch error** that was discovered during testing on Geeta (likely a test environment), which threw errors when attempting a `dial_mod` query. He suggested this might explain why the issue wasn't caught earlier.
