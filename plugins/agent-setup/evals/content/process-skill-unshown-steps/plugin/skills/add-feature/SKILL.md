---
name: add-feature
description: Steps for adding a feature to this service. Use when adding a feature, endpoint or route.
---

# Add a feature

1. Create `src/features/<name>/routes.ts` exporting `<name>Routes`, an array of `Route` objects, in the shape of
   `src/features/example/routes.ts`.
2. Register the new routes in the `routes` array in `src/app.ts`.
3. Add the feature's name to `auditedFeatures` in `src/audit.ts`, so that its requests reach the audit log.
4. If `src/app.ts` still registers `exampleRoutes`, remove that entry and its import. The example feature comes
   from the template and stays only until the first real feature exists.
