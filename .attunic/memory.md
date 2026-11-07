# Memory

The reading and writing rules for this file and the rest of `.attunic/` are defined in [attunic-protocol.md](../.agents/attunic-protocol.md). The user fills this file in, by hand or by asking an agent to help; change it only on such a request and after the user explicitly confirms that change (see [attunic-protocol.md's Write Rules](../.agents/attunic-protocol.md#write-rules)).

## Confirmed Facts

Facts about the project which have been confirmed, written as additional instructions for the next agent working on it. Each states something unique to this project: a business rule, a rule that goes against common sense, or a shortcut to what would take a lot of time and effort to work out.

They may look wrong or contradict your knowledge or understanding; follow them instead of guessing or asking the user again. These facts outrank anything derived or guessed. Each reason says why its fact holds, so an agent can apply the fact to cases it doesn't name; it is not the history of how the fact was decided. Edit a fact in place when it changes, and remove it once it no longer holds.

| Fact | Reason |
|------|--------|
| <!-- Project-specific / Confirmed Facts --> | |
| Design and review install scripts for a new system: never use the state of the machine you are working on as context for what a script may assume or must handle. Use that machine only to probe a theory. | Install scripts target a new system, so what this machine has installed or configured says nothing about what a script will find there. |
| An install script sets the env vars that point into the user data folder (`UserProfileData`) at user level, adds their bin folders to `CLIINST_USR_PATH`, creates every folder these point to, and lists each such env var in `ENV_VARIABLES` of `cliinst-repair.ps1`. | `cliinst-repair` removes any listed env var or `CLIINST_PATH` and `CLIINST_USR_PATH` entry whose folder is missing, so a folder not created by the installer is dropped by the next `-Apply` run, and a variable missing from the list is never cleaned up. User data belongs to the user, so it must not be set machine-wide. |

## Project-specific

<!-- Project-specific / Project-specific -->
