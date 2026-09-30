# Dala Dala Rush TZ 1.0.9

Release candidate: version `1.0.9`, code `10`.

Artifact: `exports/android/DalaDalaRushTZ-closed-testing-v10.aab`

SHA-256: `244951E217FA1802B9E422FB286E55BC0E52D0B83B1EECCF6DB6CCF3E984C210`

## English

- Added Route Contracts and seasonal-event rewards for clearer daily reasons
  to return to each route.
- Improved first-session guidance, route identity, Driver Reputation, Route
  Mastery, run highlights, and result recommendations.
- Added the Cloud Backup pilot interface: explicit consent, manual backup,
  restore, deletion, and a short-lived phone-move code. Cloud upload remains
  disabled in this release while two-phone testing is completed.
- Improved Settings layout on smaller Android screens and strengthened save,
  reward, referral, and route-contract safeguards.

## Kiswahili

- Tumeongeza Route Contracts na zawadi za seasonal events ili kila route iwe
  na sababu nzuri ya kurudi kila siku.
- Tumeboreshwa mafunzo ya mwanzo, utofauti wa route, Kiwango cha Huduma,
  Route Mastery, mambo muhimu ya safari na ushauri baada ya mchezo.
- Tumeongeza muonekano wa majaribio ya Cloud Backup: ridhaa, backup ya mkono,
  kurejesha data, kufuta data na code ya kuhamisha simu. Cloud upload bado
  imezimwa kwenye release hii hadi majaribio ya simu mbili yakamilike.
- Settings sasa inakaa vizuri zaidi kwenye Android ndogo, na ulinzi wa save,
  zawadi, referral na Route Contracts umeimarishwa.

## Tester Focus

Test all six routes in Swahili and English, especially route contracts,
results, saves, ads, and Android resume. Cloud Backup must remain unavailable
in this release; complete the two-phone checklist before enabling it later.

## Local Verification

- Godot 4.7.1 headless editor parse: passed.
- Logic contracts: passed.
- Backend validation tests: passed.
- Signed AAB: `jar verified.`
- Generated release manifest: includes the AdMob application ID and
  `com.google.android.gms.permission.AD_ID`.
