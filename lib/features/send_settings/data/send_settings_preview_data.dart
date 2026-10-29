// Mock stored settings for API-21/22. Values are synthetic. The default ON/OFF
// policy is still undecided by the team, so one purpose is left unset on purpose.
const sendSettingsPreviewMailbox = {
  "mailbox_ref": "demo-purchase-mailbox",
  "version": 2,
  "approval": {"RFQ": true, "CLARIFICATION": null, "COUNTER_OFFER": true},
  "allowed_supplier_ids": [
    "bfe4fb8c-eaf8-45e3-8eb7-7def7777a002",
    "bfe4fb8c-eaf8-45e3-8eb7-7def7777a004",
  ],
  "tone": "FORMAL",
  "signature": "구매팀 드림",
};

// Case-level overrides. null inherits the mailbox value for that purpose.
const sendSettingsPreviewCases = {
  "REQ-2026-1019-003": {
    "version": 1,
    "approval": {"RFQ": null, "CLARIFICATION": false, "COUNTER_OFFER": null},
  },
};

const sendSettingsPreviewSuppliers = [
  {
    "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a001",
    "name": "A사",
    "email": "sales@a-supplier.example.com",
  },
  {
    "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a002",
    "name": "B사",
    "email": "order@b-supplier.example.com",
  },
  {
    "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a003",
    "name": "C사",
    "email": "biz@c-supplier.example.com",
  },
  {
    "supplier_id": "bfe4fb8c-eaf8-45e3-8eb7-7def7777a004",
    "name": "D사",
    "email": "quote@d-supplier.example.com",
  },
];
