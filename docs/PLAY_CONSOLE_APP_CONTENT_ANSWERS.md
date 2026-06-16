# Play Console App Content Answers

Use this while completing **Policy > App content** in Google Play Console for
Dala Dala Rush TZ.

These answers match the current MVP: an offline-friendly Godot mobile game with
AdMob ads, local saves, no account login, no gambling, no real-money betting,
and no health/financial/government features.

## Let Us Know About The Content Of Your App

Recommended summary:

```text
Dala Dala Rush TZ is a family-friendly 2D endless driving game inspired by
Tanzanian city traffic. Players dodge obstacles, collect coins and passengers,
unlock vehicle skins using fake in-game coins, and can watch optional rewarded
ads for revive/double coins. The app has no login, no user-generated content,
no chat, no gambling, no betting, no real-money wagering, no financial services,
no health features, and no government services.
```

## Privacy Policy

Answer: **Yes, provide a privacy policy URL.**

Use the hosted URL for the policy based on:

```text
docs/privacy-policy.html
```

Do not submit a local file path. Google Play needs a public web URL such as a
page on your website, Google Sites, GitHub Pages, or another public hosting
location.

Suggested URL if GitHub Pages is enabled for this repository:

```text
https://kadioko.github.io/Dala-Dala-Rush/privacy-policy.html
```

Only use that URL after confirming it opens publicly in a browser.

## Sign In Details / App Access

Answer: **No, all app functionality is available without special access.**

Use this explanation if Google asks:

```text
The app does not require login, account creation, subscription access, or test
credentials. Users can open the game and play immediately.
```

## Ads

Answer: **Yes, my app contains ads.**

Ad formats used:

- Rewarded ads for revive after crash.
- Rewarded ads for double coins.
- Interstitial ads after every 2-3 completed runs.
- Banner ads only on menu/results.

Ad SDK:

```text
Google AdMob / Google Mobile Ads SDK
```

## Content Rating

Start questionnaire and answer as a game.

Recommended answers for current MVP:

- Violence: **No realistic violence.**
- Blood/gore: **No.**
- Fear/horror: **No.**
- Sexual content/nudity: **No.**
- Language/profanity: **No.**
- Controlled substances: **No.**
- Gambling: **No.**
- User-generated content: **No.**
- Online interaction/chat: **No.**
- Location sharing: **No.**
- Digital purchases: **No real-money purchases in MVP.**

Notes:

- Crashing into obstacles is cartoon/simple gameplay, not graphic violence.
- Fake coins are only in-game rewards/unlocks and are not gambling.
- If real IAP is added later, update this questionnaire.

## Target Audience And Content

Recommended age groups:

```text
13-15
16-17
18 and over
```

Do **not** select under 13 unless you intentionally want to comply with Google
Play Families/child-directed app requirements and configure child-safe ads.

Children appeal question:

```text
No, the store listing is not specifically designed to attract children.
```

Reasoning:

```text
The game is family-friendly, but it is a general-audience arcade driving game
with ads and no child-directed branding, classroom use, or children-specific
content.
```

If you choose to target children later, we must review AdMob child treatment,
ad content rating, identifiers, privacy policy wording, and Families policy.

## Data Safety

### Data Collection

Answer: **Yes, the app collects or shares user data.**

Reason: Google Mobile Ads SDK automatically collects and shares data for ads,
analytics, and fraud prevention.

### Data Types To Declare

Declare these because of AdMob:

1. **Location**
   - Approximate location
   - Purpose: Advertising or marketing, analytics, fraud prevention/security
   - Collected: Yes
   - Shared: Yes
   - Required or optional: Required for ads SDK operation

2. **App activity**
   - App interactions
   - Purpose: Advertising or marketing, analytics, fraud prevention/security
   - Collected: Yes
   - Shared: Yes
   - Required or optional: Required for ads SDK operation

3. **App info and performance**
   - Diagnostics
   - Purpose: Analytics, fraud prevention/security, app functionality if asked
   - Collected: Yes
   - Shared: Yes
   - Required or optional: Required for ads SDK operation

4. **Device or other IDs**
   - Device or other IDs
   - Purpose: Advertising or marketing, analytics, fraud prevention/security
   - Collected: Yes
   - Shared: Yes
   - Required or optional: Required for ads SDK operation

### Security Practices

Is all user data encrypted in transit?

```text
Yes
```

Can users request data deletion?

Recommended answer for MVP:

```text
No
```

Reason:

```text
The game does not create user accounts or maintain a developer-hosted user
profile database. Gameplay progress is stored locally on the device. AdMob data
is handled by Google under Google's privacy controls.
```

If Play Console expects a deletion URL, create a support/privacy page explaining
how users can reset local data by clearing app storage/uninstalling, and how to
manage Google ad personalization from Google settings.

## Government Apps

Answer:

```text
No, this is not a government app and is not made for or on behalf of a
government entity.
```

## Financial Features

Answer:

```text
No, the app does not include financial products, financial services, loans,
credit, investments, trading, cryptocurrency, money transfers, or real-money
gambling/betting.
```

If asked about monetization:

```text
The app uses advertising and fake in-game coins only. Coins cannot be exchanged
for real money or prizes.
```

## Health

Answer:

```text
No, the app does not provide health, medical, fitness, wellness, clinical,
diagnostic, treatment, medication, mental health, or health research features.
```

## Final Items Needed From You

- Public privacy policy URL.
- Support/contact email address. Current draft uses `support@kadioko.com`.
- Final app icon and feature graphic. Generated in `assets/store_listing/`.
- Store screenshots. Generated in `assets/store_listing/`.
- Confirmation that the target audience should be 13+ and not under 13.
