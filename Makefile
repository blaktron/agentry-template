# Convenience targets for developing this BriefAgent with the agentry CLI.
AGENTRY ?= agentry

.PHONY: validate dry-run run

# Offline validation: the same manifest rules and content scanners the
# registry runs at publish time.
validate:
	$(AGENTRY) validate .

# Compile the run plan (capabilities → enforcement) and print it. No
# docker needed; --allow-unsigned because a local tree has no attestation.
dry-run:
	$(AGENTRY) run --local . --dry-run --allow-unsigned --yes

# Execute once in an isolated container. Needs a docker engine and the
# model API key your runner policy names (ANTHROPIC_API_KEY by default).
# Reports and receipts land in ./agentry-out/.
run:
	$(AGENTRY) run --local . --allow-unsigned --yes --out ./agentry-out
