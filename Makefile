APP=$(shell ruby -e 'require "./lib/version" and puts ICalPal::NAME')
VERSION=$(shell ruby -e 'require "./lib/version" and puts ICalPal::VERSION')

GEM=/tmp/$(APP)-$(VERSION).gem

export GITHUB_REPO = icalPal

$(GEM): bin/* */*.rb $(APP).gemspec
	gem build $(APP).gemspec -q -o $(GEM)

clean:
	rm -fv $(GEM)

install: $(GEM)
	gem install $(GEM)

user-install: $(GEM)
	gem install --user-install $(GEM)

uninstall:
	-gem uninstall $(APP) -ax

reinstall: uninstall install

rubygems: $(GEM)
	gem push $(GEM) --otp $(CODE)

gemfury: $(GEM)
	fury push $(GEM)

publish: rubygems gemfury

release:
	github-release release -t ${APP}-${VERSION} -n "${APP} ${VERSION}"

upload:
	github-release upload -t ${APP}-${VERSION} -n "${GEM}" -R -f "${GEM}"
