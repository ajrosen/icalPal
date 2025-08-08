APP=$(shell ruby -e 'require "./lib/version" and puts ICalPal::NAME')
VERSION=$(shell ruby -e 'require "./lib/version" and puts ICalPal::VERSION')

GEM=$(APP)-$(VERSION).gem

export GITHUB_REPO = icalPal

$(GEM): bin/* */*.rb $(APP).gemspec
	gem build $(APP).gemspec -q -o $(GEM)

clean:
	rm -fv *.gem

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

github-push:
	git push

release:
	github-release release -t ${APP}-${VERSION} -n "${APP} ${VERSION}"

upload:
	github-release upload -t ${APP}-${VERSION} -n "${APP}-${VERSION}.gem" -R -f "${GEM}"
