# Mobile App Scaffold

This directory will contain the Flutter implementation for the Lost & Found mobile client.

Refer to `../../docs/blueprint.txt` Section 2 for detailed architecture & feature plan.

Planned structure (conceptual):

```text
lib/
  app/            # bootstrap (router, theme, localization)
  core/           # constants, errors, utils
  data/           # DTOs, http impl repositories
  domain/         # entities, abstract repositories
  features/       # auth, home, report, matches, profile, messages, notifications
  l10n/           # localization resources
  shared/         # reusable widgets (cards, chips, skeletons)
assets/
  images/
  fonts/
```

Next steps:

1. Initialize Flutter project here.
2. Add Riverpod + Dio dependencies.
3. Implement config provider for API base URL.
4. Scaffold Auth + Reports repositories with mock → HTTP swap pattern.
