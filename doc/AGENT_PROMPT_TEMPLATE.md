# AGENT_PROMPT_TEMPLATE.md
# Standardized Coding Agent Prompt Template

---

## How to Use This Template

For each task in `EXECUTION_PLAN.md`:
1. Copy the **full block** below starting at `---BEGIN AGENT PROMPT---`.
2. Fill in the `[BRACKETED]` fields from the task entry in `EXECUTION_PLAN.md`.
3. Paste the completed prompt to your coding agent as the **first and only message** for that session.
4. Do **not** chain multiple tasks into a single agent session. One session = one atomic task.

---

---BEGIN AGENT PROMPT---

## Mandatory Pre-Read

Before writing a single line of code, read the following files in full and confirm you have done so:

1. `ARCHITECTURE.md` — Internalize the folder structure, the layer dependency rules (§3), the repository contract (§5), the error handling strategy (§6), and the sync architecture (§7).
2. `TECH_STACK_AND_STANDARDS.md` — Internalize the exact dependency versions (§1), all coding standards including null safety, entity rules, model rules, use case rules, BLoC/Cubit standards, widget isolation rules, naming conventions, and DI registration rules (§2).

**You are not permitted to proceed until you have read both files.** If any instruction in this prompt conflicts with `ARCHITECTURE.md` or `TECH_STACK_AND_STANDARDS.md`, the architecture documents take precedence.

---

## Active Task

**Task ID:** [TASK-X.X — e.g., TASK-3.1]
**Task Title:** [e.g., Inventory Domain Layer]
**Phase:** [e.g., Phase 3: Inventory Feature]

---

## Objective

[Paste the Objective field verbatim from EXECUTION_PLAN.md for this task.]

---

## Layer Focus

[Paste the Layer Focus field verbatim from EXECUTION_PLAN.md for this task.]

**Strict constraint:** You will only create or modify files within the layer and path specified above. You must not create, modify, or import from any layer outside this scope unless it is a `core/` dependency that already exists (e.g., `core/error/failures.dart`, `core/utils/typedefs.dart`).

---

## Files to Create or Modify

[List each file path from the task's specification. For example:]
```
lib/features/inventory/domain/entities/medication.dart
lib/features/inventory/domain/repositories/inventory_repository.dart
lib/features/inventory/domain/usecases/get_medications.dart
...
```

---

## Implementation Specification

[Paste the full Specification section from EXECUTION_PLAN.md for this task, including any code snippets, entity field lists, interface signatures, or behavioral rules.]

---

## Hard Constraints

The following are non-negotiable. Violating any of these is a task failure, regardless of whether the code compiles.

**Architecture:**
- [ ] No file in a `domain/` folder imports from `data/`, `presentation/`, or any infrastructure package (`hive`, `sqflite`, `dio`, `firebase_*`, `flutter_local_notifications`).
- [ ] No file in a `data/` folder imports from `presentation/`.
- [ ] No file in a `presentation/` folder imports from `data/` repositories, datasources, or models.
- [ ] Repository interfaces are `abstract interface class`. No concrete logic.
- [ ] Use cases implement the `UseCase<T, P>` or `StreamUseCase<T, P>` interface from `core/`.
- [ ] Entities extend `Equatable`, have `const` constructors, and implement `copyWith`.
- [ ] Models have `fromJson`, `toJson`, and a `toEntity()` method. They do **not** appear in domain use case signatures.

**Code Quality:**
- [ ] Strict null safety: no `!` operator except after explicit `is` type checks.
- [ ] All function parameters and return types are explicitly typed. No `dynamic`.
- [ ] All error paths return `Either<Failure, T>` (or `Stream<Either<Failure, T>>`). No bare `throw`.
- [ ] All classes, methods, and fields have doc comments if they are public API.
- [ ] `flutter analyze` produces zero warnings or errors upon task completion.

**DI:**
- [ ] Every concrete class that will be injected is annotated with the correct `injectable` annotation (`@injectable`, `@lazySingleton`, `@singleton`, or `@LazySingleton(as: Interface)`).
- [ ] After adding new injectables, run `flutter pub run build_runner build --delete-conflicting-outputs` and include the updated `.config.dart` in your output.

**Testing:**
- [ ] Every public method in every new file has at least one corresponding unit test.
- [ ] Tests use `mocktail` for mocks. Do not use `mockito`.
- [ ] Test file paths mirror source paths under `test/` (e.g., `lib/features/inventory/domain/usecases/get_medications.dart` → `test/features/inventory/domain/usecases/get_medications_test.dart`).
- [ ] All tests pass: `flutter test test/features/[feature]/` exits 0.

---

## Definition of Done

[Paste the Definition of Done field verbatim from EXECUTION_PLAN.md for this task.]

You must self-verify every item in the Definition of Done before declaring the task complete. Output a checklist with each item explicitly marked as ✅ or ❌. If any item is ❌, fix it before finalizing output.

---

## Output Format

Provide your output in the following order:

1. **Confirmation of pre-read:** One sentence confirming you have read `ARCHITECTURE.md` and `TECH_STACK_AND_STANDARDS.md`.
2. **Implementation plan:** 3–5 bullet points describing your implementation approach before writing code. Flag any ambiguities or assumptions.
3. **Full file contents:** For each file, output a code block with the complete file content. Include the file path as a comment at the top of each block. Do not omit any imports.
4. **Build runner output** (if applicable): Confirm that `build_runner build` was run and paste any relevant output.
5. **Test results:** Paste the output of `flutter test test/features/[feature]/` (or the relevant test path).
6. **DoD checklist:** The self-verification checklist described above.

Do not provide summaries, explanations of basic concepts, or conversational filler. Output code and verification only.

---

## Context from Prior Tasks (if applicable)

[If this task depends on artifacts from a previous task, paste the relevant file contents or interface signatures here so the agent has the complete context it needs without hallucinating.]

```dart
// Example: paste the domain entity or repository interface that this task builds upon
```

---END AGENT PROMPT---

---

## Tips for Effective Agent Use

### On Context Management
- Each agent session is stateless. Always include all relevant prior-task interfaces in the "Context from Prior Tasks" section. Do not assume the agent remembers the previous session.
- For Data layer tasks, always paste the Domain layer's repository interface and entity definitions as context.
- For Presentation layer tasks, always paste the Domain entities, use case signatures, and the Failure types as context.

### On Build Artifacts
- After any task that adds new Hive types or injectable registrations, the `.config.dart` and `.g.dart` files must be regenerated and committed before the next task begins. Include these generated files in the "Context from Prior Tasks" of the next session if they are dependencies.

### On Task Sequencing
- Never start `TASK-X.2` (Data layer) before `TASK-X.1` (Domain layer) DoD is fully ✅.
- Never start `TASK-X.3` (Presentation layer) before `TASK-X.2` (Data layer) DoD is fully ✅.
- Phase 5 (`SyncQueue`, `SyncManager`) can be started in parallel with Phase 3 after Phase 0 is complete, since it only depends on `core/` infrastructure.

### On Failure Recovery
If the agent produces code that fails `flutter analyze` or fails tests:
1. Do **not** start a new session.
2. Append the error output to the same session with the prefix: `"The following errors were produced. Fix them without changing the architecture or the DoD requirements:"`
3. If after 2 correction attempts the agent still fails, break the failing file into a new, more granular sub-task.
