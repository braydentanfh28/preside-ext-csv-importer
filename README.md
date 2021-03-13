# Preside Extension: CSV Import

This is an extension for add import CSV feature to admin. It provides a new `CSV Importer` into admin system drop down options.

#### Import form
| Field | Description |
| ----- | ----------- |
| Target object | To enable CSV import to Preside object, the object must have `csvImportEnabled` enabled (true). |
| File | CSV file to upload |
| Has header? | Toggle whether your CSV file has header, true by default |


#### References

Object attributes

| Attribute | Description | Default |
| --------- | ----------- | ------- |
| `csvImportEnabled` | To enable object available for import target | **False** |
