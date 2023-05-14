TOOLCHAINS := \
	Formula/dc-toolchain-stable.rb \
	Formula/dc-toolchain-legacy.rb \
	Formula/dc-toolchain-testing.rb

all: $(TOOLCHAINS)

Envsubst = envsubst '$$FORMULA_NAME $$CONFIG_NAME' < $^ > $@

Formula/dc-toolchain-stable.rb: Formula/dc-toolchain.in
	env FORMULA_NAME=DcToolchainStable CONFIG_NAME=stable $(Envsubst)
Formula/dc-toolchain-legacy.rb: Formula/dc-toolchain.in
	env FORMULA_NAME=DcToolchainLegacy CONFIG_NAME=legacy $(Envsubst)
Formula/dc-toolchain-testing.rb: Formula/dc-toolchain.in
	env FORMULA_NAME=DcToolchainTesting CONFIG_NAME=testing $(Envsubst)

.PHONY: rebuild
rebuild:
	$(RM) $(TOOLCHAINS)
	$(MAKE) all

.PHONY: table
table:
	@printf '| Name | Description |\n'
	@printf '| --- | --- |\n'
	@brew tap-info --json jpeach/dreamcast  | jq -r '.[] | .formula_names | .[]' | sort | \
	while read name; do \
		desc=`brew info --json "$$name" | jq -r '.[] | .desc'` ; \
		name=`brew info --json "$$name" | jq -r '.[] | .name'` ; \
		printf '| [%s](./Formula/%s.rb) | %s | \n' "$$name" "$$name" "$$desc" ; \
	done

.PHONY: check
check:
	@brew audit --tap jpeach/dreamcast

# vim: set noet ts=8 sw=8 :
