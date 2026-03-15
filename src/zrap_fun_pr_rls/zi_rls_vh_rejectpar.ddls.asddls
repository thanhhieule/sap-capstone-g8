 @EndUserText.label: 'VH: Reject Reason'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.ignorePropagatedAnnotations: true
define view entity ZI_RLS_VH_RejectPAR
  as select from zpr_rejres_g8
{
  key cancel_reason_code as CancelReasonCode,
      cancel_reason_note as CancelNote
}
