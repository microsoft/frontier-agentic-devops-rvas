# CSV compatibility rule

For changes to an existing CSV export, preserve existing column positions.
Append new columns after the existing ones. A change that moves an existing
column breaks consumers that read columns by position.

Check only changes to CSV field ordering. Do not report formatting, naming,
missing comments, or unrelated test coverage.
