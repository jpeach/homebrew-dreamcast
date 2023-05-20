TOOLCHAINS := \
	Formula/dc-toolchain-stable.rb \
	Formula/dc-toolchain-legacy.rb \
	Formula/dc-toolchain-testing.rb

all: $(TOOLCHAINS)

$(TOOLCHAINS): ./bin/generate-toolchain-formula.sh
	./bin/generate-toolchain-formula.sh

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
	@shellcheck bin/*
	@brew style jpeach/dreamcast
	@brew audit --except=checksum --display-filename --tap=jpeach/dreamcast

# vim: set noet ts=8 sw=8 :
