-- the user's colour theme: maki's own UI in config/themes's colours.
-- bin/theme writes a user theme (dotfiles.toml) under ~/.config/maki/themes; the
-- plugin names it to maki once here (maki.setup is a one-shot per init.lua). A new
-- theme is picked up on the next maki start or /reload.
-- ~/.config/maki is a link to ~/dotfiles/config/maki (install).

require("maki_theme").apply()
require("golangci_lint")
require("handoff")
require("ast_grep")
require("safe_ish_yolo")
require("session_title")

maki.api.register_prompt_hint({
  slot = "conventions",
  content = [[Write plans and similar planning artifacts in Russian, unless the user asks for another language.

When working on a non-trivial coding task, pair with the user through checkpoints:
- Before the first code change, map the relevant execution path, proposed changes, alternatives or risks, and decisions that need the user's input. Stop and wait for the user's direction. Exploration is fine before this checkpoint; do not delegate implementation before it.
- After approval, work within that scope. Stop and ask before changing approach, expanding the scope, or accepting a significant trade-off. Do not demand approval for routine edits within the agreed plan.
- Before creating an MR or declaring the work MR-ready, stop with a review of the change by logical parts, tests run and not run, remaining risks, and the execution path the user should understand. Wait for the user's questions or confirmation before proceeding.
- If interrupted or asked for status, explain what has changed, why, what remains, and the current decision point. Answer follow-up questions and wait for an explicit instruction to continue; do not resume work automatically.
- For trivial changes requested directly, skip the planning pause unless a decision or surprising scope emerges.

Memory across sessions:
- At the start of a non-trivial task, check project memory using relevant tags; use only notes related to the current project.
- Save durable user preferences, architectural decisions, recurring commands, and non-obvious constraints likely to help in future sessions.
- Do not save secrets, temporary task status, or conversation dumps. Avoid duplicate notes; update existing notes when facts change.
- After an important decision or discovery, update memory promptly. Briefly tell the user when you save an important note.
- If memory conflicts with the current request or repository state, verify the current state; do not treat an old note as authoritative.]],
})

-- Private local plugin pack for development.
-- Maki snapshots the current git revision when loading the package; commit locally
-- before /reload for edits to appear. Switch src to the SSH URL for shared installs.
maki.pack.add({
  { src = "/home/danil/w/maki", version = "main" },
  { src = "/home/danil/w/maki-flant-provider", version = "main" },
}, { confirm = false })
