# Feature Specification: Profile Trophies and Collapsible Sections

**Feature Branch**: `002-profile-trophies`

**Created**: 2026-11-08

**Status**: Draft

**Input**: User description: "Aggiorna la sezione del profilo. Rendi la sezione delle quest e delle statistiche entrambi item collassabili. Aggiungi la possibilità di vedere delle card che rappresentano come dei 'trofei' chi ha nel mese attuale il primo posto per categoria di spese, singola spesa più alta, refund più alto di tutti i mesi, singolo ingresso di tutti i mesi, categoria con più spese tra tutti i mesi, singola spesa più alta tra tutti i mesi."

## Clarifications

### Session 2026-11-08

- Q: Who are the trophies for? → A: Personal records of the single local profile, to give an overview of the user's own habits. No comparison between users or profiles.
- Q: How is "highest refund" defined? → A: The refund trophy was removed from scope by the user.
- Q: How are ties handled? → A: Only the oldest element wins a tie. In rankings, elements with equal values are ordered by date, oldest first.
- Q: When a category trophy card is tapped, which elements does the top-three ranking contain? → A: The top three expense categories by total amount; transaction trophies rank the top three transactions by amount. Every trophy card opens the ranking of the elements it ranks.
- Q: How should the top-three ranking appear? → A: In a dedicated full-screen view with the trophy title and a back action.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Collapse and expand profile sections (Priority: P1)

A user opens their profile and wants to focus on one part at a time. They collapse the quests section to see the statistics more easily, then collapse the statistics section as well. The profile remembers their choices the next time they open the app.

**Why this priority**: The profile currently shows every quest and every statistic at once. Making the two sections collapsible reduces visual noise immediately, requires no new data, and is independently shippable.

**Independent Test**: Open the profile, collapse and expand each section, restart the app, and verify each section keeps its previous state.

**Acceptance Scenarios**:

1. **Given** the profile is open with both sections expanded, **When** the user taps the quests header, **Then** the quest list is hidden and the header indicates a collapsed state.
2. **Given** the quests section is collapsed, **When** the user taps the statistics header, **Then** only the statistics section collapses; the quests section remains collapsed.
3. **Given** a section is collapsed, **When** the user restarts the app and opens the profile, **Then** the section is still collapsed.
4. **Given** the quests section is expanded and the daily quest limit is reached, **When** the user views the section, **Then** the existing reset countdown and disabled state are still shown.

---

### User Story 2 - View personal trophy cards (Priority: P2)

A user opens the profile and sees a trophy section that summarizes their most notable financial records: the top expense category and the highest single expense of the current month, plus the highest income, top expense category, and highest single expense across all months. Each card shows the record value and enough context to understand it.

**Why this priority**: Trophies turn raw transaction history into a quick, motivating overview of the user's habits, which is the core value requested by the user.

**Independent Test**: With a known set of transactions, open the profile and verify that each trophy card shows the expected record and value.

**Acceptance Scenarios**:

1. **Given** transactions exist in the current month, **When** the user opens the profile, **Then** the current-month top category and highest single expense cards show the correct records.
2. **Given** transactions exist across several months, **When** the user opens the profile, **Then** the all-time highest income, top category, and highest single expense cards show the correct records.
3. **Given** a transaction is added, edited, or deleted, **When** the user returns to the profile, **Then** the affected trophies reflect the change.
4. **Given** no transaction qualifies for a trophy, **When** the user opens the profile, **Then** that card shows an explicit empty state instead of a missing or misleading value.

---

### User Story 3 - Open trophy rankings (Priority: P3)

A user taps a trophy card to see more than the single winner. A dedicated full-screen ranking opens with the trophy title and the top three elements for that trophy, ordered by value; when values are equal, the oldest element comes first.

**Why this priority**: The ranking adds depth to the trophy cards without changing the main profile overview, and it depends on the trophy calculations from User Story 2.

**Independent Test**: From a trophy card, open the ranking and verify that the first three elements and their order match the expected data, including ties.

**Acceptance Scenarios**:

1. **Given** at least three qualifying elements exist, **When** the user taps a trophy card, **Then** a dedicated full-screen ranking opens and shows exactly three elements in descending order of value.
2. **Given** two or more elements have the same value, **When** the ranking is shown, **Then** the older element appears first.
3. **Given** fewer than three qualifying elements exist, **When** the user taps the trophy card, **Then** the ranking shows all available elements.
4. **Given** a trophy card has no qualifying data, **When** the user taps it, **Then** no ranking opens and the card remains non-interactive.

---

### Edge Cases

- The user has no transactions at all: every trophy card shows an empty state and none opens a ranking.
- The user has income but no expenses: expense trophies show an empty state; the income trophy shows the record.
- Two transactions have the same amount: only the older one is shown on the trophy card; both appear in the ranking ordered by date.
- Two categories have the same total: the category whose earliest contributing transaction is older wins the card.
- An expense has no category: it participates in single-expense trophies and is grouped under an "Uncategorized" label for category trophies.
- A refunded expense or an expense split into installments: its amount and period follow the same attribution rules already used by the monthly statistics.
- Transactions dated in a future month: they are included in all-time trophies but never in the current-month trophies.
- Zero-amount transactions: they are ignored when a positive record exists; if all amounts are zero, the trophy shows an empty state.
- The category referenced by a transaction no longer exists: the transaction is treated as uncategorized.
- The profile name is empty: trophies and section collapsing still work; only quest availability is unaffected by this feature.

## Requirements *(mandatory)*

### Functional Requirements

**Collapsible profile sections**

- **FR-001**: The profile screen MUST present the quests section and the statistics section as two independently collapsible items.
- **FR-002**: Each collapsible header MUST show its section title and a visual indicator of the current expanded or collapsed state.
- **FR-003**: The whole header area MUST be tappable and MUST toggle only its own section.
- **FR-004**: Both sections MUST start expanded on first use.
- **FR-005**: The app MUST persist each section's expanded or collapsed state locally and restore it after a restart.
- **FR-006**: When a section is collapsed, its content MUST be hidden without removing it from the screen's data or breaking its behavior when expanded again.
- **FR-007**: The existing quest availability, daily-limit overlay, reset countdown, and statistic progress indicators MUST keep working unchanged when their section is expanded.
- **FR-008**: Collapsible headers MUST expose their expanded or collapsed state to assistive technologies and provide an adequate touch target.

**Trophy cards**

- **FR-009**: The profile MUST contain a trophies section that shows the user's personal records. Trophies MUST NOT compare different users or profiles.
- **FR-010**: The trophies section MUST include a card for the expense category with the highest total expense amount in the current calendar month.
- **FR-011**: The trophies section MUST include a card for the highest single expense in the current calendar month.
- **FR-012**: The trophies section MUST include a card for the highest single income entry across all months.
- **FR-013**: The trophies section MUST include a card for the expense category with the highest total expense amount across all months.
- **FR-014**: The trophies section MUST include a card for the highest single expense across all months.
- **FR-015**: The refund trophy MUST NOT be part of this feature.
- **FR-016**: The current month MUST be the user's local calendar month at the time the profile is viewed.
- **FR-017**: "Across all months" MUST consider every transaction stored locally, including transactions dated in future months.
- **FR-018**: Each trophy card MUST show the trophy title, the record value formatted for the user's locale and currency, the relevant period, and the name of the winning category or transaction.
- **FR-019**: When several elements tie for a trophy, only the oldest one MUST be shown. For transactions, oldest means the earliest transaction date; for categories, oldest means the earliest contributing transaction date.
- **FR-020**: Each trophy card MUST show an explicit empty state when no element qualifies, and MUST NOT display a zero or placeholder value as if it were a record.
- **FR-021**: Trophies MUST be recalculated from current local data whenever the profile is shown or the underlying transactions change.
- **FR-022**: Trophy amounts MUST use the same attribution rules as the monthly statistics for installments and refunds.

**Trophy rankings**

- **FR-023**: Every trophy card with qualifying data MUST be tappable and MUST open a ranking for that trophy.
- **FR-024**: A ranking MUST show at most three elements, ordered by value from highest to lowest.
- **FR-025**: Elements with equal values MUST be ordered by date, oldest first, so the ranking is deterministic.
- **FR-026**: Category trophies MUST rank expense categories by total amount; transaction trophies MUST rank the underlying transactions by amount.
- **FR-027**: A ranking MUST show all available elements when fewer than three qualify.
- **FR-028**: A ranking MUST open in a dedicated full-screen view that shows the trophy title and a back action, and MUST return the user to the profile without changing the trophy state.

**Presentation and localization**

- **FR-029**: All new user-facing text, including trophy titles, ranking labels, and empty states, MUST be provided in both English and Italian localization resources.
- **FR-030**: Amounts and dates MUST respect the user's locale and MUST NOT be hardcoded.

### Key Entities *(include if feature involves data)*

- **Trophy**: A derived, non-persisted record displayed on the profile. It has a type, a period (current month or all time), a winning value, a winning subject (category or transaction), and an optional date.
- **Trophy ranking entry**: A derived position in a trophy ranking, with a value, a date used for tie-breaking, and a subject (category or transaction).
- **Expense / income entry**: The existing locally stored transaction that provides amounts, dates, categories, refund status, and installment information.
- **Category**: The existing expense category used to aggregate category trophies.
- **Profile**: The existing single local user profile that owns the trophies and the section expansion preferences.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A user can collapse or expand either profile section with a single tap, and the other section is unaffected.
- **SC-002**: After restarting the app, 100% of profile sections keep their previous expanded or collapsed state.
- **SC-003**: All five trophy cards are visible on the profile without navigating to another screen.
- **SC-004**: For every tested dataset, each displayed trophy value matches a manual calculation from the stored transactions.
- **SC-005**: When at least three elements qualify, every ranking shows exactly three elements in a deterministic order, including ties.
- **SC-006**: Trophies reflect a transaction change by the next time the profile is shown, without requiring an app restart.
- **SC-007**: No new user-facing string appears untranslated in either supported language.

## Assumptions

- The app has a single local profile; trophies are personal records, not a leaderboard between users.
- "Top category" means the expense category with the highest total expense amount, not the category with the most individual transactions.
- The user explicitly removed the refund trophy from scope.
- Tie-breaking uses the oldest element, as requested; the same rule orders ranking entries with equal values.
- Every trophy card opens a ranking of the top three elements it ranks: category trophies rank categories, and transaction trophies rank transactions.
- Installments and refunded expenses follow the attribution rules already used by the monthly statistics, so trophy totals reconcile with the rest of the app.
- The current month is the local calendar month on the device.
- Section expansion state is stored locally alongside existing profile preferences.
- Trophies are derived at display time and require no new persisted data model or data migration.
- All new text is added to both supported language resources, English and Italian.
