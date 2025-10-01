@AbapCatalog.sqlViewName: 'ZENHANCE_TABLE2'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Ehnhance Table'
define view ZENHANCE_TABLE1 as select from zenhance_table
{
    key id as Id,
    unit_field as UnitField,
    distance as Distance
}
