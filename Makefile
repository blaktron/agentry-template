# Shortcuts for building this QuickAgent with the agentry CLI.
AGENTRY ?= agentry
# Files to hand a run, space-separated: make run FILES="notes.pdf data.csv"
FILES ?=

.PHONY: validate dry-run review run

# The registry's manifest rules and offline scanners, run here.
validate:
	$(AGENTRY) validate .

# Compile the run plan and print it: the tools, the mounts, the network.
# No docker needed. A local tree is unsigned, hence --allow-unsigned.
dry-run:
	$(AGENTRY) run --local . --dry-run --allow-unsigned --yes

# The built-in Examiner: the registry's rules, AI Review's questions and a
# model's reading of the files, without submitting anything. Needs your own
# TypeSafe key ($TYPESAFE_API_KEY).
review:
	$(AGENTRY) review .

# One run in the sandbox. Needs docker and the model your runner policy
# names (`agentry setup`). Reports and receipts land in ./agentry-out/.
run:
	$(AGENTRY) run --local . --allow-unsigned --yes --out ./agentry-out $(addprefix --file ,$(FILES))
