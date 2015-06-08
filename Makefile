image = validator-test-image
dist  = dist/assembly-benchmark-validator.tar.gz
build = validate-assembly-benchmark

.PHONY: build test bootstrap

files   = assembly.fasta references  README.md
objects = $(addprefix $(build)/,$(files))

##############################
#
# Test and push the package
#
##############################

all: test

publish: ./plumbing/push-to-s3 VERSION $(dist)
	bundle exec $^

test: $(dist)
	mkdir -p $@
	tar -xzf $< -C $@ --strip-components 1
	bundle exec kramdown $@/README.md > $@/README.html
	bundle exec htmlproof $@/README.html
	./$@/validate $(image) default

$(dist): $(objects)
	mkdir -p $(dir $@)
	tar -czf $@ --exclude '$(build)/tmp' --exclude 'Gemfile.lock' $(dir $<)

##############################
#
# Build the distributable
#
##############################

build: $(objects)

$(build)/README.md: doc/assembly-benchmark-validator.md
	cp $< $@


$(build)/assembly.fasta: $(build)
	wget $(assembly) --quiet --output-document $@

$(build)/references: $(build)
	wget $(reference) --quiet --output-document $@; tar xzvf $@ --directory $(build) 

$(build): $(shell find src)
	cp -R src $@
	mkdir -p $@/schema
	touch $@

##############################
#
# Bootstrap initial resources
#
##############################

bootstrap: image Gemfile.lock

Gemfile.lock: Gemfile
	bundle install --path vendor/bundle

image:
	git clone git@github.com:pbelmann/bbx-quast.git $@
	docker build -t $(image) $@

clean:
	rm -rf $(build) dist

##############################
#
# Urls
#
##############################

assembly = 'https://www.dropbox.com/s/wi3w568bqe1kr1e/assembly.fasta?dl=1'
reference = 'https://www.dropbox.com/s/8i002mer686an9s/reference.tar.gz?dl=0'
