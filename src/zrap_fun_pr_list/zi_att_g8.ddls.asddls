@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@EndUserText.label: 'File import CDS'
define root view entity ZI_ATT_G8
  as select from zpr_att_g8 as attachment
  composition [0..*] of ZI_LIST_G8  as _Item
  association [0..1] to I_User      as _UserCreatedBy on $projection.CreatedBy = _UserCreatedBy.UserID
  association [0..1] to I_User      as _UserUpdatedBy on $projection.LastUpdatedBy = _UserUpdatedBy.UserID
{
  key  attachment_uuid as AttachmentUUID,
  attachment as Attachment,
  mimetype as Mimetype,
  file_name as FileName,
  total_count as TotalCount,
  success_count as SuccessCount,
  warning_count as WarningCount,
  error_count as ErrorCount,
  @Semantics.user.createdBy: true
  created_by as CreatedBy,
  @Semantics.systemDateTime.createdAt: true
  created_at as CreatedAt,
  local_create_at as LocalCreateAt,
  @Semantics.user.localInstanceLastChangedBy: true
  last_updated_by as LastUpdatedBy,
  @Semantics.systemDateTime.lastChangedAt: true
  last_updated_at as LastUpdatedAt,
  @Semantics.systemDateTime.localInstanceLastChangedAt: true
  local_last_updated_at as LocalLastUpdatedAt,
  _Item,
  _UserCreatedBy,
  _UserUpdatedBy
  
}
