# features_new (Clean Architecture Copy)

This folder contains a detached copy of UI pages and entities reorganized into modules:

Modules:
- auth
- courses (includes courses, categories, groups)
- assessments (includes activities and assessments / peer evaluation)

Each module structure:
- data/
  - datasources/
  - repositories/
- domain/
  - models/
  - repositories/
  - use_cases/
- ui/
  - controllers/
  - pages/

Note: These copies are not wired into the application runtime.
