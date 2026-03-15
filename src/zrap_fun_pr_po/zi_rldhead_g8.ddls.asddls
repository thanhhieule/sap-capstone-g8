 @AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'PR header release'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZI_RLDHEAD_G8 
  as select from zpr_rlshead_g8 as header 
  composition [0..*] of ZI_RLDITEM_G8  as _Item
{
    key pr_no as PrNo,
    define_key as DefineKey,
    status as Status,
    po_no as PoNo,
    lifnr as Lifnr,
    purchaserequisitiontype as Purchaserequisitiontype,
    plant as Plant,
    purchasing_group as PurchasingGroup,
    purchasingorganization as Purchasingorganization,
    cancel_reason_code as CancelReasonCode,
    cancel_note as CancelNote,
    message_standardtable as MessageStandardtable,
    criticality as Criticality,
    url         as Url,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  @Semantics.user.localInstanceLastChangedBy: true
  local_last_changed_by as LocalLastChangedBy,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_changed_at as LocalLastChangedAt,
  @Semantics.systemDateTime.lastChangedAt: true
  last_changed_at as LastChangedAt,
    _Item
} where header.status = 'PR Released'
   or header.status = 'PO Created'
   or header.status = 'Create PO failed';
