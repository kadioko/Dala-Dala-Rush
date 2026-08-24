# Dala Dala Rush TZ 1.0.7 Release Notes

Released August 24, 2026 for closed testing.

Release: version `1.0.7`, version code `8`, target API `36`.

## English

- Added Invite & Earn with shareable player codes.
- Invited friends receive 75 welcome coins once, while inviters receive 125
  coins after a returned confirmation.
- Added milestone bonuses at 3, 5, and 10 confirmed friends.
- Made Invite & Earn clearer on the main menu with its reward shown.
- Added self-referral, duplicate, wrong-owner, malformed-code, tamper, and
  referral-limit protections.
- Added complete Swahili and English referral UI, privacy copy, save migration,
  and reward-integrity tests.

## Kiswahili

- Tumeongeza Alika & Pata yenye code za kushirikisha marafiki.
- Rafiki aliyealikwa anapata sarafu 75 mara moja, na aliyemwalika anapata
  sarafu 125 baada ya confirmation kurudi.
- Kuna bonus zaidi kwa marafiki 3, 5, na 10 waliothibitishwa.
- Alika & Pata sasa inaonekana wazi kwenye Menyu Kuu pamoja na zawadi yake.
- Tumezuia kutumia code yako, kurudia zawadi, code ya mtu mwingine, code
  iliyoharibiwa, na kuzidi kikomo cha zawadi za marafiki.
- UI ya Kiswahili na English, privacy copy, save, na reward tests
  zimesasishwa.

## Play Console Copy

English:

```text
Invite friends with your player code and earn coins after a one-time confirmation. This update adds bilingual referral UI, fair reward milestones, duplicate and self-referral protection, stronger local saves, and improved menu polish.
```

Kiswahili:

```text
Alika marafiki kwa code yako na upate sarafu baada ya confirmation ya mara moja. Tumeongeza Kiswahili na English, bonus za marafiki, ulinzi dhidi ya kurudia au kutumia code yako, save bora, na Menyu Kuu iliyoboreshwa.
```

## Final Artifact Details

- Version name: `1.0.7`
- Version code: `8`
- Target SDK: Android 16 / API 36
- Artifact: `exports/android/DalaDalaRushTZ-closed-testing-v8.aab`
- Size: `61,418,542` bytes
- SHA-256: `B2EF4D3B99E716275E34A6752459E1CCA0CDF9E458068E1A4D0CF0DD9DB665A1`
- Signing certificate: Kadioko Games release certificate present in the bundle
- Manifest: package `com.kadioko.daladalarush`, version name `1.0.7`, AdMob
  App ID, and `com.google.android.gms.permission.AD_ID` verified from the base
  manifest data
- Device QA: complete a two-phone invite and confirmation round trip after
  Play delivers the bundle
