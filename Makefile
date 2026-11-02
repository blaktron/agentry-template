# Shortcuts for building this QuickAgent with the agentry CLI.
AGENTRY ?= agentry
# Files to hand a run, space-separated: make run FILES="notes.pdf data.csv"
FILES ?=
# The folder the targets work on: the template itself, or a variant, as in
# make validate DIR=variants/persistent
DIR ?= .
VARIANTS := $(wildcard variants/*)

.PHONY: validate validate-variants check dry-run review run

# The registry's manifest rules and offline scanners, run here.
validate:
	$(AGENTRY) validate $(DIR)

# The same checks on every variant under variants/.
validate-variants:
	@for v in $(VARIANTS); do echo "== $$v"; $(AGENTRY) validate $$v || exit 1; done

# The template and each of its variants.
check: validate validate-variants

# Compile the run plan and print it: the tools, the mounts, the network.
# No docker needed. A local tree is unsigned, hence --allow-unsigned.
dry-run:
	$(AGENTRY) run --local $(DIR) --dry-run --allow-unsigned --yes

# The built-in Examiner: the registry's rules, AI Review's questions and a
# model's reading of the files, without submitting anything. Needs your own
# TypeSafe key ($TYPESAFE_API_KEY).
review:
	$(AGENTRY) review $(DIR)

# One run in the sandbox. Needs docker and the model your runner policy
# names (`agentry setup`). Reports and receipts land in ./agentry-out/.
# A persistent variant is not run: install it with
# agentry agent install --local DIR --allow-unsigned (see its README).
run:
	$(AGENTRY) run --local $(DIR) --allow-unsigned --yes --out ./agentry-out $(addprefix --file ,$(FILES))
