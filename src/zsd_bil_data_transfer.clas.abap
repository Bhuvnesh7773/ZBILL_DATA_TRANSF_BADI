CLASS zsd_bil_data_transfer DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .


  PUBLIC SECTION.

    INTERFACES if_badi_interface .
    INTERFACES if_sd_bil_data_transfer .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS ZSD_BIL_DATA_TRANSFER IMPLEMENTATION.


  METHOD if_sd_bil_data_transfer~change_data.
*      Mandatory step for all implementations:
*   Copy the importing parameters to the changing parameters.

    MOVE-CORRESPONDING bil_doc TO bil_doc_res.
    MOVE-CORRESPONDING bil_doc_item TO bil_doc_item_res.
    MOVE-CORRESPONDING bil_doc_item_contr TO bil_doc_item_contr_res.

*   Example field manipulation of billing document header field:
*   Here we're replacing the billing document date with the current date in time zone UTC.
    GET TIME STAMP FIELD DATA(ts).
    CONVERT TIME STAMP ts TIME ZONE 'UTC' INTO DATE bil_doc_res-billingdocumentdate.

    IF bil_doc_item-salesdocumentitemcategory = 'CB99' OR bil_doc_item-salesdocumentitemcategory = 'CB98' .
      billingdocumentitemisrejected = abap_true.
    ENDIF .

*    IF bil_doc_item-BATCH IS INITIAL.
*      IF bil_doc_item-salesdocumentitemcategory = 'JNLN'  AND bil_doc_item-storagelocation IS INITIAL  .
*        billingdocumentitemisrejected = abap_true.
*      ENDIF .
*    ENDIF.

*    IF bil_doc_item-salesdocumentitemcategory = 'NLN' AND bil_doc_item-higherlvlitmofbatspltitm IS not INITIAL  .
*               billingdocumentitemisrejected = abap_true.
*    ENDIF .

    IF bil_doc_item-salesdocumentitemcategory = 'NLN' AND bil_doc_item-billingquantity is INITIAL  .
               billingdocumentitemisrejected = abap_true.
    ENDIF .

    IF bil_doc_item-salesdocumentitemcategory = 'JNLN' AND bil_doc_item-billingquantity is INITIAL  .
               billingdocumentitemisrejected = abap_true.
    ENDIF .

bil_doc_res-yy1_businessplace_bdh = bil_doc-businessplace.

SELECT SINGLE FiscalYear from I_FiscalCalendarDate where CalendarDate = @bil_doc-billingdocumentdate and FiscalYearVariant = 'V3' into @data(fiscalyear).

bil_doc_res-yy1_fiscalyear_bdh = fiscalyear.

*DATA:   lv_timestamp TYPE timestamp.CONVERT DATE SY-DATLO TIME SY-TIMLO INTO TIME STAMP lv_timestamp TIME ZONE SY-ZONLO.

*if bil_doc-billingdocumentdate is INITIAL.
bil_doc_res-billingdocumentdate = SY-DATLO.
*ENDIF.
""""""""""""""""""""""""""""""""""""""""Commented BY BSR on 16.09.2024 on req Chinmay

*if sy-tabix = 1.
*bil_doc_res-yy1_deliverynumber_bdh = bil_doc_item-referencesddocument  .
*endif.



""""""""""""""""""""""""""""""""""""""""""""""""""""""

"""added by NSR ""'""""
if bil_doc_res-yy1_forwardingagent_bdh is INITIAL.
select  SINGLE  supplier from I_SDDocumentPartner WITH PRIVILEGED ACCESS
where PartnerFunction = 'SP' and SDDocument = @bil_doc_item-referencesddocument
into @data(SUPPLIER) .
IF SUPPLIER IS NOT INITIAL.
bil_doc_res-yy1_forwardingagent_bdh = SUPPLIER.
CLEAR SUPPLIEr .
ENDIF.
endif.
""""""""""""""""""BY Ranveer singh  on 17.12.2024"""""""""""""""""
if bil_doc_res-yy1_shiptype_bdh = '03'.
select  SINGLE  supplier from I_SDDocumentPartner WITH PRIVILEGED ACCESS
where PartnerFunction = 'SP' and SDDocument = @bil_doc_item-referencesddocument
into @data(SUPPLIER1) .
IF SUPPLIER1 IS INITIAL.
    billingdocumentitemisrejected = abap_true.
    billgdocitmrejectionreasontext = |Error: Forwarding Agent is missing for ShipType = 03|.
ENDIF.
ENDIF.
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
*if bil_doc-billingdocumenttype = 'F8'.
*  SELECT single BillingDocument from I_BillingDocumentItemBasic where referencesddocument = @bil_doc_item-referencesddocument into @data(Billing_doc).
*  SELECT single * from I_BillingDocument where BillingDocument = @Billing_doc and AccountingTransferStatus = 'E' into @Data(data1).
*  if sy-subrc = 0.
*  billingdocumentitemisrejected = abap_true.
*  endif.
*endif.
********************************************************Chinmay******************
IF bil_doc_res-yy1_distance_bdh is INITIAL .
    billingdocumentitemisrejected = abap_true.
    billgdocitmrejectionreasontext = |Distance in delivery { bil_doc_item-referencesddocument } is empty|.
ELSEIF bil_doc_res-yy1_distance_bdhu is INITIAL .
    billingdocumentitemisrejected = abap_true.
    billgdocitmrejectionreasontext = |Distance unit in delivery { bil_doc_item-referencesddocument } is empty|.
ENDIF.

***********************************************Chinmay*******11.09.2025***********************
*LOOP AT bil_doc_item INTO DATA(VAL1).

 SELECT SINGLE PRICESPECIFICATIONPRODUCTGROUP FROM I_PRODUCTSALESDELIVERY WITH PRIVILEGED ACCESS
 WHERE PRODUCT = @bil_doc_item-material AND PRODUCTSALESORG = @bil_doc_item-salesordersalesorganization
 AND PRODUCTDISTRIBUTIONCHNL = @bil_doc_item-salesorderdistributionchannel
 INTO @DATA(IT_FIN).

IF IT_FIN = 'SP' OR IT_FIN = 'DP' OR IT_FIN = 'NP' OR IT_FIN = 'ZP' OR IT_FIN = 'MP' .
  IF bil_doc-yy1_mfmsdistrict2_bdh = '000000' .
    billingdocumentitemisrejected = abap_true.
        billgdocitmrejectionreasontext = 'FMS District is missing'.
  ENDIF.
  IF bil_doc-yy1_mfmsdistrictpincod_bdh is INITIAL .
    billingdocumentitemisrejected = abap_true.
        billgdocitmrejectionreasontext = 'mFMS District Pin Code is missing'.
  ENDIF.
  IF bil_doc-yy1_mmfsidtobedone_bdh is INITIAL .
    billingdocumentitemisrejected = abap_true.
        billgdocitmrejectionreasontext = 'mFMS ID is missing'.
  ENDIF.
  IF bil_doc-yy1_mfmsidtype_bdh is INITIAL .
    billingdocumentitemisrejected = abap_true.
        billgdocitmrejectionreasontext = 'mFMS ID Type is missing'.
  ENDIF.
ENDIF.
*ENDLOOP.

*****************************************************************************************************
IF bil_doc-billingdocumenttype = 'F2'
   OR bil_doc-billingdocumenttype = 'CBRE' OR bil_doc-billingdocumenttype = 'F8'
   OR bil_doc-billingdocumenttype = 'JSTO'.

  DATA(lv_orig)       = bil_doc-yy1_mmfsidtobedone_bdh.
  CONDENSE lv_orig NO-GAPS.    " remove regular spaces/tabs

  " Make a copy and remove every non-digit (keep only 0-9)
  DATA(lv_only_digits) = lv_orig.
  REPLACE ALL OCCURRENCES OF REGEX '[^0-9]' IN lv_only_digits WITH ''.

  " If original is empty OR original differs from only-digits -> invalid
*  IF lv_orig IS INITIAL
  IF lv_orig <> lv_only_digits.
    billingdocumentitemisrejected = abap_true.
    billgdocitmrejectionreasontext = 'MMFS ID must be numeric only'.
  ENDIF.

ENDIF.




  ENDMETHOD.
ENDCLASS.
