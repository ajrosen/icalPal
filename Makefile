APP=$(shell ruby -e 'require "./lib/version" and puts ICalPal::NAME')
VERSION=$(shell ruby -e 'require "./lib/version" and puts ICalPal::VERSION')

GEM=$(APP)-$(VERSION).gem

export GITHUB_REPO = icalPal

$(GEM): bin/* */*.rb $(APP).gemspec
	/usr/bin/gem build $(APP).gemspec -q -o $(GEM)

clean:
	@rm -rf .yardoc doc
	@rm -fv *.gem

install: $(GEM)
	gem install $(GEM)

user-install: $(GEM)
	gem install --user-install $(GEM)

uninstall:
	-gem uninstall $(APP) -ax

reinstall: uninstall install

doc:
	rm -rf .yardoc doc
	yard doc --protected --private --embed-mixins --no-stats --no-progress

version:			# make version LEVEL=[major,minor,patch]
	bump $(LEVEL)

rubygems: $(GEM)
	gem push $(GEM) --otp $(CODE)

gemfury: $(GEM)
	fury push $(GEM)

publish: rubygems gemfury

github-push:
	git push

release:
	github-release release -t ${APP}-${VERSION} -n "${APP} ${VERSION}"

upload:
	github-release upload -t ${APP}-${VERSION} -n "${APP}-${VERSION}.gem" -R -f "${GEM}"

all: doc $(GEM) release upload
